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