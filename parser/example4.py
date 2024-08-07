# Import statements
import math
from sys import exit

# Function definition with default, keyword, and variable-length arguments
def my_function(a, b=10, *args, **kwargs):
    # Local variable assignment
    c = a + b

    # Conditional statement with comparison and logical operators
    if a > b and b != 0:
        c = c / b
    elif a == 0 or b == 0:
        return None
    else:
        c -= a

    # Loop with a complex range and conditional break
    for i in range(1, 10):
        if i == 5:
            break
        c += i

    # Try-except-finally with specific exceptions
    try:
        result = c / (a - b)
    except ZeroDivisionError:
        result = float('inf')
    finally:
        print("Calculation complete.")

    # List comprehension with conditional expression
    squares = [x**2 for x in range(10) if x % 2 == 0]

    # Dictionary comprehension
    square_dict = {x: x**2 for x in range(5)}

    # Set and generator expressions
    unique_squares = {x**2 for x in range(-4, 5)}
    sum_of_inverse = sum(1/x for x in range(1, 11))

    # Return statement with multiple values
    return result, squares, square_dict, unique_squares, sum_of_inverse

# Class definition with inheritance and method overriding
class MyClass(int):
    # Constructor method
    def __init__(self, value):
        self.value = value

    # Magic method for string representation
    def __str__(self):
        return f"MyClass value: {self.value}"

# Lambda function with conditional expression
add_or_subtract = lambda x, y: x + y if x > y else x - y

# Async function and await expression
async def fetch_data():
    import aiohttp
    async with aiohttp.ClientSession() as session:
        async with session.get('http://example.com') as response:
            return await response.text()

# Execution of an async function
import asyncio
asyncio.run(fetch_data())

# Global variables used in an expression
global_var = 10
result = global_var * 2 - 5

# Using eval to execute a string as Python code
evaluated_result = eval('result + 10')

# Decorator usage
@staticmethod
def static_method():
    print("This is a static method.")

# Error raising with specific error type
if result < 0:
    raise ValueError("Result is negative!")

# Return an instance of the class
instance = MyClass(10)
print(instance)
