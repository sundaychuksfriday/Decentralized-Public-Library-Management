;; Inter-library Loan Contract
;; Coordinates sharing between library systems

;; Constants for loan status
(define-constant STATUS_REQUESTED u1)
(define-constant STATUS_APPROVED u2)
(define-constant STATUS_DENIED u3)
(define-constant STATUS_IN_TRANSIT u4)
(define-constant STATUS_RECEIVED u5)
(define-constant STATUS_RETURNED u6)
(define-constant STATUS_COMPLETED u7)

;; Error codes
(define-constant ERR_UNAUTHORIZED u401)
(define-constant ERR_ALREADY_EXISTS u409)
(define-constant ERR_NOT_FOUND u404)
(define-constant ERR_INVALID_STATUS u405)

;; Data maps
(define-map inter-library-loans
  { loan-id: uint }
  {
    book-id: uint,
    source-library: uint,
    destination-library: uint,
    request-date: uint,
    approval-date: (optional uint),
    due-date: (optional uint),
    return-date: (optional uint),
    status: uint,
    requester: principal
  }
)

;; Counter for loan IDs
(define-data-var next-loan-id uint u1)

;; Define the contract administrator
(define-data-var contract-admin principal tx-sender)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get contract-admin))
)

;; Request an inter-library loan
(define-public (request-loan
    (book-id uint)
    (source-library uint)
    (destination-library uint))
  (let ((loan-id (var-get next-loan-id)))
    (begin
      (asserts! (is-admin) (err ERR_UNAUTHORIZED))

      (map-set inter-library-loans
        {loan-id: loan-id}
        {
          book-id: book-id,
          source-library: source-library,
          destination-library: destination-library,
          request-date: block-height,
          approval-date: none,
          due-date: none,
          return-date: none,
          status: STATUS_REQUESTED,
          requester: tx-sender
        }
      )

      (var-set next-loan-id (+ loan-id u1))

      (ok loan-id)
    )
  )
)

;; Approve a loan request
(define-public (approve-loan (loan-id uint) (due-date uint))
  (let ((loan (map-get? inter-library-loans {loan-id: loan-id})))
    (begin
      (asserts! (is-admin) (err ERR_UNAUTHORIZED))
      (asserts! (is-some loan) (err ERR_NOT_FOUND))

      (let ((current-loan (unwrap-panic loan)))
        (asserts! (is-eq (get status current-loan) STATUS_REQUESTED) (err ERR_INVALID_STATUS))

        (ok (map-set inter-library-loans
          {loan-id: loan-id}
          (merge current-loan {
            approval-date: (some block-height),
            due-date: (some due-date),
            status: STATUS_APPROVED
          })
        ))
      )
    )
  )
)

;; Mark loan as in transit
(define-public (mark-in-transit (loan-id uint))
  (let ((loan (map-get? inter-library-loans {loan-id: loan-id})))
    (begin
      (asserts! (is-admin) (err ERR_UNAUTHORIZED))
      (asserts! (is-some loan) (err ERR_NOT_FOUND))

      (let ((current-loan (unwrap-panic loan)))
        (asserts! (is-eq (get status current-loan) STATUS_APPROVED) (err ERR_INVALID_STATUS))

        (ok (map-set inter-library-loans
          {loan-id: loan-id}
          (merge current-loan {
            status: STATUS_IN_TRANSIT
          })
        ))
      )
    )
  )
)

;; Mark loan as received
(define-public (mark-received (loan-id uint))
  (let ((loan (map-get? inter-library-loans {loan-id: loan-id})))
    (begin
      (asserts! (is-admin) (err ERR_UNAUTHORIZED))
      (asserts! (is-some loan) (err ERR_NOT_FOUND))

      (let ((current-loan (unwrap-panic loan)))
        (asserts! (is-eq (get status current-loan) STATUS_IN_TRANSIT) (err ERR_INVALID_STATUS))

        (ok (map-set inter-library-loans
          {loan-id: loan-id}
          (merge current-loan {
            status: STATUS_RECEIVED
          })
        ))
      )
    )
  )
)

;; Mark loan as returned
(define-public (mark-returned (loan-id uint))
  (let ((loan (map-get? inter-library-loans {loan-id: loan-id})))
    (begin
      (asserts! (is-admin) (err ERR_UNAUTHORIZED))
      (asserts! (is-some loan) (err ERR_NOT_FOUND))

      (let ((current-loan (unwrap-panic loan)))
        (asserts! (is-eq (get status current-loan) STATUS_RECEIVED) (err ERR_INVALID_STATUS))

        (ok (map-set inter-library-loans
          {loan-id: loan-id}
          (merge current-loan {
            return-date: (some block-height),
            status: STATUS_RETURNED
          })
        ))
      )
    )
  )
)

;; Complete the loan process
(define-public (complete-loan (loan-id uint))
  (let ((loan (map-get? inter-library-loans {loan-id: loan-id})))
    (begin
      (asserts! (is-admin) (err ERR_UNAUTHORIZED))
      (asserts! (is-some loan) (err ERR_NOT_FOUND))

      (let ((current-loan (unwrap-panic loan)))
        (asserts! (is-eq (get status current-loan) STATUS_RETURNED) (err ERR_INVALID_STATUS))

        (ok (map-set inter-library-loans
          {loan-id: loan-id}
          (merge current-loan {
            status: STATUS_COMPLETED
          })
        ))
      )
    )
  )
)

;; Get loan details
(define-read-only (get-loan (loan-id uint))
  (map-get? inter-library-loans {loan-id: loan-id})
)

;; Set contract admin
(define-public (set-contract-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (ok (var-set contract-admin new-admin))
  )
)

