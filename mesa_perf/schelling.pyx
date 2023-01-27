# distutils: language = c++
# cython: profile=True
import mesa
cimport cython_time
cimport space
import random


random.seed(1)


cdef class SchellingAgent(cython_time.Agent):
    cdef public object pos
    cdef public int type
    def __init__(self, unique_id, pos, model, agent_type):
        """
        Create a new Schelling agent.

        Args:
           unique_id: Unique identifier for the agent.
           x, y: Agent initial location.
           agent_type: Indicator for the agent's type (minority=1, majority=0)
        """
        super().__init__(unique_id, model)
        self.pos = pos
        self.type = agent_type

    cpdef step(self):
        cdef int similar = 0
        # for neighbor in self.model.grid.iter_neighbors(self.pos, True):
        neighbors = self.model.grid.get_neighbors_mview(self.pos, True, 1, False)
        cdef int i
        for i in range(len(neighbors)):
            neighbor = neighbors[i]
            if neighbor.type == self.type:
                similar += 1

        # If unhappy, move:
        if similar < self.model.homophily:
            self.model.grid.move_to_empty(self)
        else:
            self.model.happy += 1


cdef class Schelling:
    cdef int width
    cdef int height
    cdef double density
    cdef double minority_pc
    cdef public int homophily
    cdef cython_time.SchedulerPythonDict schedule
    cdef public space._Grid grid
    cdef public int happy
    cdef bint running
    def __init__(self, width=20, height=20, density=0.8, minority_pc=0.2, homophily=3):
        """ """

        self.width = width
        self.height = height
        self.density = density
        self.minority_pc = minority_pc
        self.homophily = homophily

        self.schedule = cython_time.SchedulerPythonDict(self, True)
        self.grid = space._Grid(width, height, True)

        self.happy = 0

        # Set up agents
        # We use a grid iterator that returns
        # the coordinates of a cell as well as
        # its contents. (coord_iter)
        cdef int row, col
        cdef int x, y
        cdef int agent_type
        cdef SchellingAgent agent
        cdef int unique_id = 0
        for row in range(self.width):
            for col in range(self.height):
                x = row
                y = col
                if random.random() < self.density:
                    if random.random() < self.minority_pc:
                        agent_type = 1
                    else:
                        agent_type = 0

                    agent = SchellingAgent(unique_id, (x, y), self, agent_type)
                    self.grid.place_agent(agent, (x, y))
                    self.schedule.add(agent)
                    unique_id += 1

        self.running = True

    def step(self):
        self.happy = 0  # Reset counter of happy agents
        self.schedule.step()

        if self.happy == self.schedule.get_agent_count():
            self.running = False


import time
tic = time.time()
cdef Schelling model
model = Schelling()
for i in range(1000):
    model.step()
print(time.time() - tic)
