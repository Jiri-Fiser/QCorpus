a, b = b, a

with open("a.txt", "rt") as f:
    for i in m:
        g()

async with g():
    m()

def x(m):
    pass

match x:=command.split():
    case ["quit"] if obj is not None:
        quit_game(lambda x: x + 1)
    case ["look"]:
        current_room.describe()
    case ["get", obj]:
        character.get(obj, current_room)
    case ["go", direction]:
        current_room = current_room.neighbor(direction)


assert 0 < x < 10, "x out of range"

try:
    print("a")
except (TypeError, ValueError) as e:
    raise TypeError("Invalid type") from e
except Exception as e:
    ...
except:
    pass
finally:
    pass

try:
    print("b")
except* Exception as g:
    pass

x = 5
def xx (z):
    global x, y
    nonlocal a, b
    x = 5

xx(3)
print(x)