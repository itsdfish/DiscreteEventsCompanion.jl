using Distributions, Random, BenchmarkTools
using SimJulia, ResumableFunctions

Random.seed!(8710) # set random number seed for reproducibility
num_customers = 10_000 # total number of customers generated
num_servers = 100 # number of servers
mu = 1.0 / 2 # service rate
lam = 0.9 # arrival rate
arrival_dist = Exponential(1 / lam) # interarrival time distriubtion
service_dist = Exponential(1 / mu); # service time distribution

@resumable function customer(env::Environment, server::Resource, id::Integer, time_arr::Float64, dist_serve::Distribution)
    @yield timeout(env, time_arr) # customer arrives
    #println("Customer $id arrived: ", now(env))
    @yield request(server) # customer starts service
    #println("Customer $id entered service: ", now(env))
    @yield timeout(env, rand(dist_serve)) # server is busy
    @yield release(server) # customer exits service
    #println("Customer $id exited service: ", now(env))
end

function initialize!(sim, arrival_dist, service_dist, num_customers, server)
    arrival_time = 0.0
    for i = 1:num_customers # initialize customers
        arrival_time += rand(arrival_dist)
        @process customer(sim, server, i, arrival_time, service_dist)
    end
end

function benchmark(arrival_dist, service_dist, num_customers, num_servers)
    sim = Simulation() # initialize simulation environment
    server = Resource(sim, num_servers) # initialize servers
    initialize!(sim, arrival_dist, service_dist, num_customers, server)
    run(sim) # run simulation
end

@btime benchmark(arrival_dist, service_dist, num_customers, num_servers)

# 256.218 ms (1420467 allocations: 75.07 MiB)
