import time

start = time.time()

for i in range(1_000_000):
    x = i ** 0.5

end = time.time()
print("Time taken:", end - start, "seconds")
