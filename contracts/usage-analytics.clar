;; Usage Analytics Contract
;; Tracks popularity of materials to guide acquisitions

;; Error codes
(define-constant ERR_UNAUTHORIZED u401)
(define-constant ERR_ALREADY_EXISTS u409)
(define-constant ERR_NOT_FOUND u404)
(define-constant ERR_INVALID_RATING u405)

;; Data maps
(define-map book-analytics
  { book-id: uint }
  {
    borrow-count: uint,
    rating-sum: uint,
    rating-count: uint,
    last-borrowed: uint,
    popularity-score: uint
  }
)

;; Define the contract administrator
(define-data-var contract-admin principal tx-sender)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get contract-admin))
)

;; Initialize analytics for a book
(define-public (initialize-analytics (book-id uint))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? book-analytics {book-id: book-id})) (err ERR_ALREADY_EXISTS))

    (ok (map-set book-analytics
      {book-id: book-id}
      {
        borrow-count: u0,
        rating-sum: u0,
        rating-count: u0,
        last-borrowed: u0,
        popularity-score: u0
      }
    ))
  )
)

;; Record a book borrowing
(define-public (record-borrow (book-id uint))
  (let ((analytics (map-get? book-analytics {book-id: book-id})))
    (begin
      (asserts! (is-admin) (err ERR_UNAUTHORIZED))

      (if (is-some analytics)
        (let ((current-analytics (unwrap-panic analytics)))
          (ok (map-set book-analytics
            {book-id: book-id}
            (merge current-analytics {
              borrow-count: (+ (get borrow-count current-analytics) u1),
              last-borrowed: block-height,
              popularity-score: (calculate-popularity
                (+ (get borrow-count current-analytics) u1)
                (get rating-sum current-analytics)
                (get rating-count current-analytics)
                block-height)
            })
          ))
        )
        (err ERR_NOT_FOUND)
      )
    )
  )
)

;; Record a book rating (1-5)
(define-public (record-rating (book-id uint) (rating uint))
  (let ((analytics (map-get? book-analytics {book-id: book-id})))
    (begin
      (asserts! (is-admin) (err ERR_UNAUTHORIZED))
      (asserts! (and (>= rating u1) (<= rating u5)) (err ERR_INVALID_RATING))

      (if (is-some analytics)
        (let ((current-analytics (unwrap-panic analytics)))
          (let (
            (new-rating-sum (+ (get rating-sum current-analytics) rating))
            (new-rating-count (+ (get rating-count current-analytics) u1))
          )
            (ok (map-set book-analytics
              {book-id: book-id}
              (merge current-analytics {
                rating-sum: new-rating-sum,
                rating-count: new-rating-count,
                popularity-score: (calculate-popularity
                  (get borrow-count current-analytics)
                  new-rating-sum
                  new-rating-count
                  (get last-borrowed current-analytics))
              })
            ))
          )
        )
        (err ERR_NOT_FOUND)
      )
    )
  )
)

;; Calculate popularity score
;; Simple algorithm: (borrow-count * 10) + (average-rating * 20)
(define-private (calculate-popularity (borrow-count uint) (rating-sum uint) (rating-count uint) (last-borrowed uint))
  (let (
    (borrow-factor (* borrow-count u10))
    (rating-factor (if (> rating-count u0)
                      (* (/ (* rating-sum u100) rating-count) u2)
                      u0))
    (recency-factor (if (> last-borrowed u0) u10 u0))
  )
    (+ (+ borrow-factor rating-factor) recency-factor)
  )
)

;; Get book analytics
(define-read-only (get-book-analytics (book-id uint))
  (map-get? book-analytics {book-id: book-id})
)

;; Get average rating
(define-read-only (get-average-rating (book-id uint))
  (let ((analytics (map-get? book-analytics {book-id: book-id})))
    (if (is-some analytics)
      (let ((current-analytics (unwrap-panic analytics)))
        (if (> (get rating-count current-analytics) u0)
          (ok (/ (* (get rating-sum current-analytics) u100) (get rating-count current-analytics)))
          (ok u0)
        )
      )
      (err ERR_NOT_FOUND)
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

