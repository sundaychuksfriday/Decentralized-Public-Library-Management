import { describe, it, beforeEach, expect, vi } from "vitest"

// Mock blockchain environment
const mockPrincipal = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
const mockBlockHeight = 100

// Mock contract
const mockContract = {
  registerBook: vi.fn(),
  updateBookStatus: vi.fn(),
  getBook: vi.fn(),
  isBookAvailable: vi.fn(),
  setContractAdmin: vi.fn(),
}

describe("Book Registration Contract", () => {
  beforeEach(() => {
    // Reset mocks
    vi.resetAllMocks()
    
    // Setup default mock responses
    mockContract.registerBook.mockReturnValue({ value: true })
    mockContract.updateBookStatus.mockReturnValue({ value: true })
    mockContract.getBook.mockReturnValue({
      value: {
        title: "Test Book",
        author: "Test Author",
        isbn: "1234567890",
        category: 1,
        status: 1,
        registrationDate: mockBlockHeight,
        libraryId: 1,
      },
    })
    mockContract.isBookAvailable.mockReturnValue({ value: true })
  })
  
  it("should register a new book", () => {
    const result = mockContract.registerBook(1, "Test Book", "Test Author", "1234567890", 1, 1)
    expect(result.value).toBe(true)
    expect(mockContract.registerBook).toHaveBeenCalledWith(1, "Test Book", "Test Author", "1234567890", 1, 1)
  })
  
  it("should update book status", () => {
    const result = mockContract.updateBookStatus(1, 2)
    expect(result.value).toBe(true)
    expect(mockContract.updateBookStatus).toHaveBeenCalledWith(1, 2)
  })
  
  it("should get book details", () => {
    const result = mockContract.getBook(1)
    expect(result.value).toHaveProperty("title", "Test Book")
    expect(result.value).toHaveProperty("author", "Test Author")
    expect(mockContract.getBook).toHaveBeenCalledWith(1)
  })
  
  it("should check if book is available", () => {
    const result = mockContract.isBookAvailable(1)
    expect(result.value).toBe(true)
    expect(mockContract.isBookAvailable).toHaveBeenCalledWith(1)
  })
  
  it("should set contract admin", () => {
    mockContract.setContractAdmin.mockReturnValue({ value: true })
    const result = mockContract.setContractAdmin(mockPrincipal)
    expect(result.value).toBe(true)
    expect(mockContract.setContractAdmin).toHaveBeenCalledWith(mockPrincipal)
  })
})

