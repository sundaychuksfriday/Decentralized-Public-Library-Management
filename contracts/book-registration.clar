;; Book Registration Contract
;; Records details of library materials

;; Constants for book status
(define-constant STATUS_AVAILABLE u1)
(define-constant STATUS_BORROWED u2)
(define-constant STATUS_RESERVED u3)
(define-constant STATUS_MAINTENANCE u4)
(define-constant STATUS_LOST u5)

;; Constants for book categories
(define-constant CATEGORY_FICTION u1)
(define-constant CATEGORY_NON_FICTION u2)
(define-constant CATEGORY_REFERENCE u3)
(define-constant CATEGORY_CHILDREN u4)
(define-constant CATEGORY_YOUNG_ADULT u5)

;; Error codes
(define-constant ERR_UNAUTHORIZED u401)
(define-constant ERR_ALREADY_EXISTS u409)
(define-constant ERR_NOT_FOUND u404)

;; Data maps
(define-map books
  { book-id: uint }
  {
    title: (string-utf8 100),
    author: (string-utf8 100),
    isbn: (string-utf8 20),
    category: uint,
    status: uint,
    registration-date: uint,
    library-id: uint
  }
)

;; Define the contract administrator
(define-data-var contract-admin principal tx-sender)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get contract-admin))
)

;; Register a new book
(define-public (register-book
    (book-id uint)
    (title (string-utf8 100))
    (author (string-utf8 100))
    (isbn (string-utf8 20))
    (category uint)
    (library-id uint))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? books {book-id: book-id})) (err ERR_ALREADY_EXISTS))

    (ok (map-set books
      {book-id: book-id}
      {
        title: title,
        author: author,
        isbn: isbn,
        category: category,
        status: STATUS_AVAILABLE,
        registration-date: block-height,
        library-id: library-id
      }
    ))
  )
)

;; Update book status
(define-public (update-book-status (book-id uint) (new-status uint))
  (let ((book-data (map-get? books {book-id: book-id})))
    (begin
      (asserts! (is-admin) (err ERR_UNAUTHORIZED))
      (asserts! (is-some book-data) (err ERR_NOT_FOUND))

      (ok (map-set books
        {book-id: book-id}
        (merge (unwrap-panic book-data) {status: new-status})
      ))
    )
  )
)

;; Get book details
(define-read-only (get-book (book-id uint))
  (map-get? books {book-id: book-id})
)

;; Check if book is available
(define-read-only (is-book-available (book-id uint))
  (let ((book-data (map-get? books {book-id: book-id})))
    (if (is-some book-data)
      (is-eq (get status (unwrap-panic book-data)) STATUS_AVAILABLE)
      false
    )
  )
)

;; Set contract admin
(define-public (set-contract-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (ok (var-set contract-admin new-admin))
  )
)

