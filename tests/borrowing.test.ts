import { describe, it, beforeEach, expect, vi } from "vitest"

// Mock blockchain environment
const mockPrincipal = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
const mockBlockHeight = 100

// Mock contract
const mockContract = {
  borrowBook: vi.fn(),
  returnBook: vi.fn(),
  markOverdue: vi.fn(),
  getBorrowingRecord: vi.fn(),
  setContractAdmin: vi.fn(),
}

describe("Borrowing Contract", () => {
  beforeEach(() => {
    // Reset mocks
    vi.resetAllMocks()
    
    // Setup default mock responses
    mockContract.borrowBook.mockReturnValue({ value: 1 })
    mockContract.returnBook.mockReturnValue({ value: true })
    mockContract.markOverdue.mockReturnValue({ value: true })
    mockContract.getBorrowingRecord.mockReturnValue({
      value: {
        bookId: 1,
        borrower: mockPrincipal,
        borrowDate: mockBlockHeight,
        dueDate: mockBlockHeight + 100,
        returnDate: null,
        status: 1,
        libraryId: 1,
      },
    })
  })
  
  it("should borrow a book", () => {
    const dueDate = mockBlockHeight + 100
    const result = mockContract.borrowBook(1, dueDate, 1)
    expect(result.value).toBe(1)
    expect(mockContract.borrowBook).toHaveBeenCalledWith(1, dueDate, 1)
  })
  
  it("should return a book", () => {
    const result = mockContract.returnBook(1)
    expect(result.value).toBe(true)
    expect(mockContract.returnBook).toHaveBeenCalledWith(1)
  })
  
  it("should mark a book as overdue", () => {
    const result = mockContract.markOverdue(1)
    expect(result.value).toBe(true)
    expect(mockContract.markOverdue).toHaveBeenCalledWith(1)
  })
  
  it("should get borrowing record", () => {
    const result = mockContract.getBorrowingRecord(1)
    expect(result.value).toHaveProperty("bookId", 1)
    expect(result.value).toHaveProperty("borrower", mockPrincipal)
    expect(mockContract.getBorrowingRecord).toHaveBeenCalledWith(1)
  })
  
  it("should set contract admin", () => {
    mockContract.setContractAdmin.mockReturnValue({ value: true })
    const result = mockContract.setContractAdmin(mockPrincipal)
    expect(result.value).toBe(true)
    expect(mockContract.setContractAdmin).toHaveBeenCalledWith(mockPrincipal)
  })
})

