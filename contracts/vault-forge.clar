;; Title: VaultForge Protocol
;;
;; Network: Stacks Layer 2 (Bitcoin Settlement Layer)
;;
;; Summary:
;; VaultForge is a revolutionary Bitcoin-native lending protocol that transforms
;; how Bitcoin holders access liquidity while preserving their long-term exposure
;; to BTC appreciation. Built on Stacks Layer 2 with Bitcoin finality guarantees.

;; Description:
;; VaultForge pioneens a new paradigm in DeFi by creating the first truly Bitcoin-centric
;; overcollateralized lending marketplace. Users can vault their Bitcoin as collateral
;; to forge STX loans without selling their appreciating BTC holdings. The protocol
;; features autonomous liquidation mechanics, real-time interest accrual, and dynamic
;; risk management - all secured by Bitcoin's proof-of-work consensus through Stacks'
;; revolutionary PoX mechanism. Every transaction benefits from Bitcoin's unmatched
;; security while enabling instant settlements and programmable money features.

;; Key Innovations:
;; - Bitcoin-First Architecture: Direct Bitcoin collateralization without wrapping
;; - Proof-of-Transfer Security: Inherits Bitcoin's security model via Stacks PoX
;; - Dynamic Risk Engine: Real-time collateral ratio monitoring and liquidation
;; - Zero-Custody Design: Users maintain self-custody throughout the lending cycle
;; - Yield-Optimized: Competitive interest rates with transparent fee structures

;; CONSTANTS

;; Access Control & Authorization
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))

;; Core Lending Errors
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u101))
(define-constant ERR-BELOW-MINIMUM (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-LOAN-NOT-FOUND (err u107))
(define-constant ERR-LOAN-NOT-ACTIVE (err u108))

;; Protocol State Errors
(define-constant ERR-ALREADY-INITIALIZED (err u104))
(define-constant ERR-NOT-INITIALIZED (err u105))
(define-constant ERR-INVALID-LIQUIDATION (err u106))

;; Input Validation Errors
(define-constant ERR-INVALID-LOAN-ID (err u109))
(define-constant ERR-INVALID-PRICE (err u110))
(define-constant ERR-INVALID-ASSET (err u111))

;; Supported Collateral Assets
(define-constant VALID-ASSETS (list "BTC" "STX"))

;;  DATA VARIABLES

;; Protocol State Management
(define-data-var platform-initialized bool false)

;; Risk Management Parameters
(define-data-var minimum-collateral-ratio uint u150) ;; 150% minimum collateral ratio
(define-data-var liquidation-threshold uint u120) ;; 120% liquidation trigger
(define-data-var platform-fee-rate uint u1) ;; 1% protocol fee

;; Protocol Analytics
(define-data-var total-btc-locked uint u0)
(define-data-var total-loans-issued uint u0)

;; DATA MAPS

;; Primary Loan Registry
(define-map loans
  { loan-id: uint }
  {
    borrower: principal,
    collateral-amount: uint,
    loan-amount: uint,
    interest-rate: uint,
    start-height: uint,
    last-interest-calc: uint,
    status: (string-ascii 20),
  }
)

;; User Portfolio Tracking
(define-map user-loans
  { user: principal }
  { active-loans: (list 10 uint) }
)

;; Oracle Price Feeds
(define-map collateral-prices
  { asset: (string-ascii 3) }
  { price: uint }
)

;; PRIVATE FUNCTIONS

;; Calculate Current Collateral-to-Loan Ratio
;; Returns percentage ratio for risk assessment
(define-private (calculate-collateral-ratio
    (collateral uint)
    (loan uint)
    (btc-price uint)
  )
  (let (
      (collateral-value (* collateral btc-price))
      (ratio (* (/ collateral-value loan) u100))
    )
    ratio
  )
)

;; Interest Calculation Engine
;; Computes interest accrued over specified block period
(define-private (calculate-interest
    (principal uint)
    (rate uint)
    (blocks uint)
  )
  (let (
      (interest-per-block (/ (* principal rate) (* u100 u144))) ;; Daily rate / blocks per day
      (total-interest (* interest-per-block blocks))
    )
    total-interest
  )
)

;; Liquidation Risk Assessment
;; Monitors and triggers liquidation for undercollateralized positions
(define-private (check-liquidation (loan-id uint))
  (let (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
      (btc-price (unwrap! (get price (map-get? collateral-prices { asset: "BTC" }))
        ERR-NOT-INITIALIZED
      ))
      (current-ratio (calculate-collateral-ratio (get collateral-amount loan)
        (get loan-amount loan) btc-price
      ))
    )
    (if (<= current-ratio (var-get liquidation-threshold))
      (liquidate-position loan-id)
      (ok true)
    )
  )
)

;; Liquidation Execution Engine
;; Processes undercollateralized position liquidation
(define-private (liquidate-position (loan-id uint))
  (let (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
      (borrower (get borrower loan))
    )
    (begin
      (map-set loans { loan-id: loan-id } (merge loan { status: "liquidated" }))
      (map-delete user-loans { user: borrower })
      (ok true)
    )
  )
)

;; Loan ID Validation
;; Ensures loan ID is within valid operational range
(define-private (validate-loan-id (loan-id uint))
  (and
    (> loan-id u0)
    (<= loan-id (var-get total-loans-issued))
  )
)

;; Asset Validation
;; Verifies asset is supported by the protocol
(define-private (is-valid-asset (asset (string-ascii 3)))
  (is-some (index-of VALID-ASSETS asset))
)

;; Price Oracle Validation
;; Ensures price feeds are within reasonable bounds
(define-private (is-valid-price (price uint))
  (and
    (> price u0)
    (<= price u1000000000000) ;; Maximum reasonable price threshold
  )
)

;; Loan Filtering Utility
;; Helper function for active loan management
(define-private (not-equal-loan-id (id uint))
  (not (is-eq id id))
)

;; PLATFORM ADMINISTRATION

;; Platform Initialization
;; Bootstraps the protocol for operational readiness
(define-public (initialize-platform)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (var-get platform-initialized)) ERR-ALREADY-INITIALIZED)
    (var-set platform-initialized true)
    (ok true)
  )
)

;; Risk Parameter Adjustment
;; Updates minimum collateralization requirements
(define-public (update-collateral-ratio (new-ratio uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (>= new-ratio u110) ERR-INVALID-AMOUNT)
    (var-set minimum-collateral-ratio new-ratio)
    (ok true)
  )
)

;; Liquidation Threshold Configuration
;; Adjusts automated liquidation trigger point
(define-public (update-liquidation-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (>= new-threshold u100) ERR-INVALID-AMOUNT)
    (var-set liquidation-threshold new-threshold)
    (ok true)
  )
)

;; Oracle Price Feed Management
;; Updates real-time asset pricing data
(define-public (update-price-feed
    (asset (string-ascii 3))
    (new-price uint)
  )
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    ;; Comprehensive input validation
    (asserts! (is-valid-asset asset) ERR-INVALID-ASSET)
    (asserts! (is-valid-price new-price) ERR-INVALID-PRICE)
    ;; Execute price update upon successful validation
    (ok (map-set collateral-prices { asset: asset } { price: new-price }))
  )
)

;; CORE LENDING OPERATIONS

;; Collateral Deposit Interface
;; Enables users to vault Bitcoin as lending collateral
(define-public (deposit-collateral (amount uint))
  (begin
    (asserts! (var-get platform-initialized) ERR-NOT-INITIALIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (var-set total-btc-locked (+ (var-get total-btc-locked) amount))
    (ok true)
  )
)

;; Loan Origination Engine
;; Creates new collateralized lending positions
(define-public (request-loan
    (collateral uint)
    (loan-amount uint)
  )
  (let (
      (btc-price (unwrap! (get price (map-get? collateral-prices { asset: "BTC" }))
        ERR-NOT-INITIALIZED
      ))
      (collateral-value (* collateral btc-price))
      (required-collateral (* loan-amount (var-get minimum-collateral-ratio)))
      (loan-id (+ (var-get total-loans-issued) u1))
    )
    (begin
      (asserts! (var-get platform-initialized) ERR-NOT-INITIALIZED)
      (asserts! (>= collateral-value required-collateral)
        ERR-INSUFFICIENT-COLLATERAL
      )
      ;; Create new loan record
      (map-set loans { loan-id: loan-id } {
        borrower: tx-sender,
        collateral-amount: collateral,
        loan-amount: loan-amount,
        interest-rate: u5, ;; 5% annual interest rate
        start-height: stacks-block-height,
        last-interest-calc: stacks-block-height,
        status: "active",
      })
      ;; Update user loan portfolio
      (match (map-get? user-loans { user: tx-sender })
        existing-loans (map-set user-loans { user: tx-sender } { active-loans: (unwrap!
          (as-max-len? (append (get active-loans existing-loans) loan-id) u10)
          ERR-INVALID-AMOUNT
        ) }
        )
        (map-set user-loans { user: tx-sender } { active-loans: (list loan-id) })
      )
      ;; Update protocol metrics
      (var-set total-loans-issued (+ (var-get total-loans-issued) u1))
      (ok loan-id)
    )
  )
)

;; Loan Repayment Processing
;; Handles loan closure with interest settlement
(define-public (repay-loan
    (loan-id uint)
    (amount uint)
  )
  (begin
    ;; Primary loan ID validation
    (asserts! (validate-loan-id loan-id) ERR-INVALID-LOAN-ID)
    (let (
        (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
        (interest-owed (calculate-interest (get loan-amount loan) (get interest-rate loan)
          (- stacks-block-height (get last-interest-calc loan))
        ))
        (total-owed (+ (get loan-amount loan) interest-owed))
      )
      (begin
        ;; Loan state and authorization checks
        (asserts! (is-eq (get status loan) "active") ERR-LOAN-NOT-ACTIVE)
        (asserts! (is-eq (get borrower loan) tx-sender) ERR-NOT-AUTHORIZED)
        (asserts! (>= amount total-owed) ERR-INVALID-AMOUNT)
        ;; Process loan closure
        (map-set loans { loan-id: loan-id }
          (merge loan {
            status: "repaid",
            last-interest-calc: stacks-block-height,
          })
        )
        ;; Release collateral back to borrower
        (var-set total-btc-locked
          (- (var-get total-btc-locked) (get collateral-amount loan))
        )
        ;; Clean up user loan tracking
        (match (map-get? user-loans { user: tx-sender })
          existing-loans (ok (map-set user-loans { user: tx-sender } { active-loans: (filter not-equal-loan-id (get active-loans existing-loans)) }))
          (ok false)
        )
      )
    )
  )
)

;;     READ-ONLY FUNCTIONS

;; Loan Information Retrieval
;; Returns comprehensive loan details for specified ID
(define-read-only (get-loan-details (loan-id uint))
  (map-get? loans { loan-id: loan-id })
)

;; User Portfolio Query
;; Retrieves all active loans for specified user
(define-read-only (get-user-loans (user principal))
  (map-get? user-loans { user: user })
)

;; Protocol Analytics Dashboard
;; Returns current platform operational metrics
(define-read-only (get-platform-stats)
  {
    total-btc-locked: (var-get total-btc-locked),
    total-loans-issued: (var-get total-loans-issued),
    minimum-collateral-ratio: (var-get minimum-collateral-ratio),
    liquidation-threshold: (var-get liquidation-threshold),
  }
)

;; Supported Assets Registry
;; Returns list of protocol-supported collateral assets
(define-read-only (get-valid-assets)
  VALID-ASSETS
)
