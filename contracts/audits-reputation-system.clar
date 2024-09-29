;; Constants and Token Setup
(define-constant contract-owner tx-sender)
(define-constant max-auditors u100)
(define-constant max-mint-amount u1000)
(define-constant err-not-authorized (err u101))
(define-constant max-token-supply u1000000000)
(define-constant decay-rate u10) ;; 10% decay per period
(define-constant decay-period u52560) ;; ~1 year

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

;; Auditor Management Functions
(define-public (verify-auditor (new-auditor principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (is-none (map-get? auditors new-auditor)) err-already-auditor)
    (asserts! (< (var-get auditor-count) max-auditors) err-max-auditors-reached)
    (map-set auditors new-auditor true)
    (var-set auditor-count (+ (var-get auditor-count) u1))
    (ok true)))

(define-public (remove-auditor (auditor principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (is-some (map-get? auditors auditor)) err-already-auditor)
    (map-delete auditors auditor)
    (var-set auditor-count (- (var-get auditor-count) u1))
    (ok true)))

(define-read-only (get-auditor-count)
  (ok (var-get auditor-count)))

(define-read-only (is-auditor (address principal))
  (default-to false (map-get? auditors address)))
