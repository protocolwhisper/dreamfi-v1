import boa

interest = boa.load("interestRate.vy")


    
borrow_interest = interest.calculateBorrowInterest(500, 1000)

print(f"Borrow Interest Rate: {(borrow_interest / 10**27) * 100}%")
