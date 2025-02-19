;; audit-reputation
;; This smart contract manages an audit reputation system, including the handling of auditors,
;; reputation tokens, role-based access control, audits, reputation decay, and reputation transfer.

;; Constants
(define-constant contract-owner tx-sender)
(define-constant max-auditors u100)
(define-constant max-mint-amount u1000)
(define-constant err-not-authorized (err u101))
(define-constant err-already-auditor (err u102))
(define-constant err-max-auditors-reached (err u103))
(define-constant err-mint-limit-exceeded (err u104))
(define-constant err-zero-amount (err u105))
(define-constant err-insufficient-balance (err u106))
(define-constant err-self-transfer (err u108))
(define-constant max-token-supply u1000000000)
(define-constant decay-rate u10) ;; 10% decay per period
(define-constant decay-period u52560) ;; Approximately 1 year in blocks (assuming 10-minute block time)

;; Token definition
(define-fungible-token reputation-token u1000000000)

;; Data maps and vars
(define-data-var token-name (string-ascii 32) "Reputation Token")
(define-data-var token-symbol (string-ascii 10) "REPT")
(define-data-var token-decimals uint u6)
(define-data-var token-uri (optional (string-utf8 256)) none)
(define-data-var auditor-count uint u0)
(define-data-var last-decay-block uint u0)

;; Maps
(define-map auditors principal bool)
(define-map whitelist principal bool)
(define-map roles principal (string-ascii 10))
(define-map reputation-timestamps principal uint)

;; Private functions
(define-private (safe-add (a uint) (b uint))
  (if (<= (+ a b) u18446744073709551615)
    (ok (+ a b))
    (err u100)))

(define-private (safe-subtract (a uint) (b uint))
  (if (>= a b)
    (ok (- a b))
    (err u101)))

(define-private (apply-decay (balance uint) (last-update uint))
  (let
    (
      (current-block block-height)
      (periods-passed (/ (- current-block last-update) decay-period))
      (decay-factor (pow (- u100 decay-rate) periods-passed))
    )
    (/ (* balance decay-factor) (pow u100 periods-passed))
  )
)

;; Public functions

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-authorized)
    (asserts! (> amount u0) err-zero-amount)
    (asserts! (<= amount (ft-get-balance reputation-token sender)) err-insufficient-balance)
    (asserts! (not (is-eq sender recipient)) err-self-transfer)
    (match (ft-transfer? reputation-token amount sender recipient)
      success (begin
        (print memo)
        (map-set reputation-timestamps recipient block-height)
        (ok true))
      error (err u3))))

(define-public (verify-auditor (new-auditor principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (is-none (map-get? auditors new-auditor)) err-already-auditor)
    (asserts! (< (var-get auditor-count) max-auditors) err-max-auditors-reached)
    (map-set auditors new-auditor true)
    (var-set auditor-count (+ (var-get auditor-count) u1))
    (print {event: "auditor_verified", auditor: new-auditor})
    (ok true)))

(define-public (burn (amount uint) (owner principal))
  (begin
    (asserts! (is-eq tx-sender owner) err-not-authorized)
    (asserts! (> amount u0) err-zero-amount)
    (asserts! (<= amount (ft-get-balance reputation-token owner)) err-insufficient-balance)
    (ft-burn? reputation-token amount owner)))

(define-public (remove-auditor (auditor principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (is-some (map-get? auditors auditor)) err-already-auditor)
    (map-delete auditors auditor)
    (var-set auditor-count (- (var-get auditor-count) u1))
    (ok true)))

(define-public (audit-auditor (auditor principal))
  (begin
    (asserts! (is-auditor auditor) err-not-authorized)
    (print {event: "auditor-audited", auditor: auditor})
    (ok true)))

(define-public (decay-reputation)
  (let
    (
      (current-block block-height)
      (last-decay (var-get last-decay-block))
    )
    (if (>= (- current-block last-decay) decay-period)
      (begin
        (var-set last-decay-block current-block)
        (ok true))
      (err u109)) ;; Error: Not enough time has passed for decay
  )
)

(define-private (calculate-quality-score (completeness uint) (accuracy uint) (timeliness uint))
    (/ (+ completeness (* accuracy u2) timeliness) u4))


(define-read-only (get-decayed-balance (user principal))
  (let ((last-update (default-to u0 (map-get? reputation-timestamps user))))
    (ok (apply-decay (ft-get-balance reputation-token user) last-update))))


(define-read-only (is-whitelisted (user principal))
  (default-to false (map-get? whitelist user)))

(define-read-only (is-auditor (address principal))
  (default-to false (map-get? auditors address)))

(define-read-only (get-name)
  (ok (var-get token-name)))

(define-read-only (get-symbol)
  (ok (var-get token-symbol)))

(define-read-only (get-decimals)
  (ok (var-get token-decimals)))

(define-read-only (get-balance (who principal))
  (ok (ft-get-balance reputation-token who)))

(define-read-only (get-total-supply)
  (ok (ft-get-supply reputation-token)))

(define-read-only (get-token-uri)
  (ok (var-get token-uri)))

(define-read-only (get-role (user principal))
  (default-to "user" (map-get? roles user)))

(define-read-only (check-max-supply)
  (let ((current-supply (ft-get-supply reputation-token)))
    (if (> current-supply max-token-supply)
      (err u107) ;; Error: Maximum token supply exceeded
      (ok true))))

(define-read-only (get-auditor-count)
  (ok (var-get auditor-count)))

(define-public (get-contract-owner)
  (ok contract-owner))

;; Additional constants
(define-constant err-invalid-score (err u110))
(define-constant err-invalid-audit-data (err u111))
(define-constant err-audit-not-found (err u112))
(define-constant min-audit-score u0)
(define-constant max-audit-score u100)

;; Additional data maps
(define-map audit-records
    { audit-id: uint, auditor: principal }
    { score: uint, timestamp: uint, status: (string-ascii 20) })
(define-map auditor-stats principal 
    { total-audits: uint, 
      average-score: uint,
      reputation-multiplier: uint })
(define-map staking-positions
    principal
    { amount: uint, locked-until: uint })

;; Staking functionality
(define-public (stake-tokens (amount uint) (lock-period uint))
    (let
        ((sender tx-sender)
         (current-time stacks-block-height)
         (unlock-time (+ current-time lock-period)))
        (begin
            (asserts! (> amount u0) err-zero-amount)
            (asserts! (<= amount (ft-get-balance reputation-token sender)) err-insufficient-balance)
            (try! (ft-transfer? reputation-token amount sender (as-contract tx-sender)))
            (map-set staking-positions sender
                { amount: amount,
                  locked-until: unlock-time })
            (print {event: "tokens_staked", staker: sender, amount: amount, unlock-time: unlock-time})
            (ok true))))

(define-public (unstake-tokens)
    (let
        ((sender tx-sender)
         (position (unwrap! (map-get? staking-positions sender) err-not-authorized))
         (current-time stacks-block-height))
        (begin
            (asserts! (>= current-time (get locked-until position)) err-not-authorized)
            (try! (as-contract (ft-transfer? reputation-token
                                           (get amount position)
                                           (as-contract tx-sender)
                                           sender)))
            (map-delete staking-positions sender)
            (print {event: "tokens_unstaked", staker: sender, amount: (get amount position)})
            (ok true))))

;; Enhanced audit management
(define-public (submit-audit-report 
    (audit-id uint)
    (completeness uint)
    (accuracy uint)
    (timeliness uint)
    (audit-data (string-utf8 500)))
    (let
        ((sender tx-sender)
         (quality-score (calculate-quality-score completeness accuracy timeliness)))
        (begin
            (asserts! (is-auditor sender) err-not-authorized)
            (asserts! (and (>= quality-score min-audit-score) 
                          (<= quality-score max-audit-score)) 
                     err-invalid-score)
            (map-set audit-records
                { audit-id: audit-id, auditor: sender }
                { score: quality-score,
                  timestamp: stacks-block-height,
                  status: "completed" })
            (update-auditor-stats sender quality-score)
            (print {event: "audit_submitted",
                   auditor: sender,
                   audit-id: audit-id,
                   score: quality-score})
            (ok true))))

(define-private (update-auditor-stats (auditor principal) (new-score uint))
    (let
        ((current-stats (default-to
            { total-audits: u0,
              average-score: u0,
              reputation-multiplier: u100 }
            (map-get? auditor-stats auditor)))
         (new-total (+ (get total-audits current-stats) u1))
         (new-average (/ (+ (* (get average-score current-stats)
                              (get total-audits current-stats))
                           new-score)
                        new-total)))
        (map-set auditor-stats
            auditor
            { total-audits: new-total,
              average-score: new-average,
              reputation-multiplier: (calculate-reputation-multiplier new-average) })))

(define-private (calculate-reputation-multiplier (average-score uint))
    (if (>= average-score u90)
        u150  ;; 1.5x multiplier for excellent performance
        (if (>= average-score u80)
            u125  ;; 1.25x multiplier for good performance
            u100))) ;; 1x multiplier for standard performance

;; Read-only functions for querying data
(define-read-only (get-audit-record (audit-id uint) (auditor principal))
    (map-get? audit-records { audit-id: audit-id, auditor: auditor }))

(define-read-only (get-auditor-statistics (auditor principal))
    (map-get? auditor-stats auditor))

(define-read-only (get-staking-position (staker principal))
    (map-get? staking-positions staker))

(define-read-only (calculate-stake-rewards (staker principal))
    (let
        ((position (unwrap! (map-get? staking-positions staker) (ok u0)))
         (locked-time (- stacks-block-height (get locked-until position)))
         (base-reward-rate u5)) ;; 5% base annual reward rate
        (ok (/ (* (get amount position) base-reward-rate locked-time)
               (* u100 decay-period)))))