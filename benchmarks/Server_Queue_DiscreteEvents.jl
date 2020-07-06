using DiscreteEvents, DataStructures, Distributions, Random, BenchmarkTools

mutable struct Server
    capacity::Int
    ids::Vector{Int}
end

Server(capacity) = Server(capacity, Int[])

is_full(s) = length(s.ids) == s.capacity ? true : false

remove!(s, id) = filter!(x-> x != id, s.ids)

add!(s, id) = push!(s.ids, id)

Random.seed!(8710) # set random number seed for reproducibility
num_customers = 10_000 # total number of customers generated
num_servers = 100 # number of servers
mu = 1.0 / 2 # service rate
lam = 0.9 # arrival rate
arrival_dist = Exponential(1 / lam) # interarrival time distriubtion
service_dist = Exponential(1 / mu); # service time distribution

function enter_line(clock, server, id, service_dist, arrival_time)
    delay!(clock, arrival_time)
    #now!(clock, fun(println, "Customer $id arrived: ", clock.time))
    if is_full(server)
        now!(clock, fun(println, "Customer $id is waiting: ", clock.time))
        wait!(clock, fun(()->!is_full(server)))
    end
    #now!(clock, fun(println,"Customer $id starting service: ", clock.time))
    add!(server, id)
    tΔ = rand(service_dist)
    delay!(clock, tΔ)
    leave(clock, server, id)
end

function leave(clock, server, id)
    #now!(clock, fun(println, "Customer $id finishing service: ", clock.time))
    remove!(server, id)
end

function initialize!(clock, arrival_dist, service_dist, num_customers, server)
    arrival_time = 0.0
    for i in 1:num_customers
        arrival_time += rand(arrival_dist)
        process!(clock, Prc(i, enter_line, server, i, service_dist, arrival_time), 1)
    end
end

function benchmark(arrival_dist, service_dist, num_customers, num_servers)
    clock = Clock()
    server = Server(num_servers)
    initialize!(clock, arrival_dist, service_dist, num_customers, server)
    run!(clock, 10^8)
end

@btime benchmark(arrival_dist, service_dist, num_customers, num_servers)

# 256.218 ms (1420467 allocations: 75.07 MiB)
