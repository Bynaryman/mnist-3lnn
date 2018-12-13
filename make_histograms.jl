using SigmoidNumbers
using StatPlots 


plotly()

MNIST_DIM = 28*28
NB_NEURON = 20
NB_OUTPUT = 10

# to print posit repartition
P4 = Posit{16,0}
D1 = [P4(x) for x in 0b0000000000000000:0b0111111111111111]
D2 = [P4(x) for x in 0b1000000000000001:0b1111111111111111]
D3 = [D2; D1]
D4 = [x for x in Float64.(D3) if x > -6 && x <6]

f = open("./weights_raw.txt")
lines = readlines(f)

hidden_weights = Array{Float64}(NB_NEURON * MNIST_DIM)
output_weights = Array{Float64}(NB_OUTPUT * NB_NEURON)

for i = 1:(NB_NEURON * MNIST_DIM)
    hidden_weights[i] = parse.(Float64, lines[i])
end

for i = 1:(NB_OUTPUT * NB_NEURON)
    output_weights[i] = parse.(Float64, lines[i+(MNIST_DIM * NB_NEURON)])
end

p1 = histogram(hidden_weights, bins=30, label="repartition of hidden weights", color="orange")
p2 = histogram(output_weights, bins=30, label="repartition of output weights")
p3 = histogram(D4, bins=30, label="repartition of posit<16,0>", color="green")
#p3 = histogram(Float64.(D3), label="repartition of posits<16,0>", color="green")
plot(p1, p2, p3, layout=(1,3))
gui()


close(f)
