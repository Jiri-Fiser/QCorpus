async def m(w):
    async for i in input():
        x = await w

def iterator():
    yield 1

def overiter():
    yield from iterator()

class X(object, base2):
    x = 3
    p:int = 0
    x:int

    def __init__(self):
        self.q = 1

    def get_q(self):
        return self.q

    @staticmethod
    def clsname():
        return "X"

    @property
    def qq(self):
        return self.q