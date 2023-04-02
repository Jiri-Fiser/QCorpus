class X(object):
    p = 0

    def __init__(self):
        self.q = 1

    def get_q(self):
        return self.q

    @property
    def qq(self):
        return self.q