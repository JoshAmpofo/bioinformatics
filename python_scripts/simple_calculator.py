#!/usr/bin/env python3


"""
A script that does simple calculations on two numbers.
Performs operations like:
    - sum
    - difference
    - product
    - division
"""


number_input_1 = int(input("Enter a number: "))
number_input_2 = int(input("Enter another number: "))

print("===== OPERATIONS ARE BEGINNING =====")


# Addition
add_nums = number_input_1 + number_input_2

# subtraction
subt_nums = number_input_1 - number_input_2

# multiplication
mult_nums = number_input_1 * number_input_2

# division
if number_input_2 == 0:
    raise ZeroDivisionError("ZeroDivisionError. Cannot divide by 0.")

else:
    div_nums = number_input_1 / number_input_2


# Print results
print(f"Addition: {number_input_1} + {number_input_2} = {add_nums}\n")
print(f"Subtraction: {number_input_1} - {number_input_2} = {subt_nums}\n")
print(f"Multiplication: {number_input_1} * {number_input_2} = {mult_nums}\n")
print(f"Division: {number_input_1} / {number_input_2} = {div_nums}")

print("===== END OF OPERATIONS =====")
