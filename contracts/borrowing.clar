;; Borrowing Contract
;; Manages lending and returns of materials

;; Constants for borrowing status
(define-constant STATUS_ACTIVE u1)
(define-constant STATUS_RETURNED u2)
(define-constant STATUS_OVERDUE u3)
(define-constant STATUS_LOST u4)

;; Error codes
(define-constant ERR_UNAUTHORIZED u401)
(define-constant ERR_ALREADY_EXISTS u409)
(define-constant ERR_NOT_FOUND u404)
(define-constant ERR_BOOK_UNAVAILABLE u405)
(define-constant ERR_INVALID_RETURN u406)

;; Data maps
(define-map borrowing-records
  { borrow-id: uint }
  {
    book-id: uint,
    borrower: principal,
    borrow-date: uint,
    due-date: uint,
    return-date: (optional uint),
    status: uint,
    library-id: uint
  }
)

;; Counter for borrowing IDs
(define-data-var next-borrow-id uint u1)

;; Define the contract administrator
(define-data-var contract-admin principal tx-sender)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get contract-admin))
)

;; Borrow a book
(define-public (borrow-book
    (book-id uint)
    (due-date uint)
    (library-id uint))
  (let ((borrow-id (var-get next-borrow-id)))
    (begin
      ;; Only librarians (admin) can record borrows
      (asserts! (is-admin) (err ERR_UNAUTHORIZED))

      ;; Check if book is available (would call book-registration contract in a real implementation)
      ;; For simplicity, we're not making a contract call here

      (map-set borrowing-records
        {borrow-id: borrow-id}
        {
          book-id: book-id,
          borrower: tx-sender,
          borrow-date: block-height,
          due-date: due-date,
          return-date: none,
          status: STATUS_ACTIVE,
          library-id: library-id
        }
      )

      (var-set next-borrow-id (+ borrow-id u1))

      (ok borrow-id)
    )
  )
)

;; Return a book
(define-public (return-book (borrow-id uint))
  (let ((record (map-get? borrowing-records {borrow-id: borrow-id})))
    (begin
      (asserts! (is-admin) (err ERR_UNAUTHORIZED))
      (asserts! (is-some record) (err ERR_NOT_FOUND))

      (let ((current-record (unwrap-panic record)))
        (asserts! (is-eq (get status current-record) STATUS_ACTIVE) (err ERR_INVALID_RETURN))

        (ok (map-set borrowing-records
          {borrow-id: borrow-id}
          (merge current-record {
            return-date: (some block-height),
            status: STATUS_RETURNED
          })
        ))
      )
    )
  )
)

;; Mark borrowing as overdue
(define-public (mark-overdue (borrow-id uint))
  (let ((record (map-get? borrowing-records {borrow-id: borrow-id})))
    (begin
      (asserts! (is-admin) (err ERR_UNAUTHORIZED))
      (asserts! (is-some record) (err ERR_NOT_FOUND))

      (let ((current-record (unwrap-panic record)))
        (asserts! (is-eq (get status current-record) STATUS_ACTIVE) (err ERR_INVALID_RETURN))

        (ok (map-set borrowing-records
          {borrow-id: borrow-id}
          (merge current-record {
            status: STATUS_OVERDUE
          })
        ))
      )
    )
  )
)

;; Get borrowing record
(define-read-only (get-borrowing-record (borrow-id uint))
  (map-get? borrowing-records {borrow-id: borrow-id})
)

;; Set contract admin
(define-public (set-contract-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (ok (var-set contract-admin new-admin))
  )
)

