using SigmoidNumbers

TYPEOUT = Posit{4,0}
MNIST_DIM = 28*28
NB_NEURON = 20
NB_OUTPUT = 10

f = open("./weights_raw.txt")
lines = readlines(f)

hidden_weights = Array{TYPEOUT}(NB_NEURON, MNIST_DIM)
output_weights = Array{TYPEOUT}(NB_OUTPUT, NB_NEURON)

for i = 1:NB_NEURON
    hidden_weights[i, :] = Array{TYPEOUT}(parse.(Float64, lines[(((i-1)*MNIST_DIM)+1):(i*MNIST_DIM)]))
end

for i = 1:NB_OUTPUT
	output_weights[i, :] = Array{TYPEOUT}(parse.(Float64, lines[(((i-1)*NB_NEURON)+1)+(MNIST_DIM*NB_NEURON):(i*NB_NEURON)+(MNIST_DIM*NB_NEURON)]))
	# uncomment below to see difference between posit 16 values and fp64
	#if (i == NB_OUTPUT)
	#	show(IOContext(STDOUT, limit=true), "text/plain", (Float64.(TYPEOUT.(parse.(Float64, lines[(((i-1)*NB_NEURON)+1)+(MNIST_DIM*NB_NEURON):(i*NB_NEURON)+(MNIST_DIM*NB_NEURON)])))))
	#end
end

mkpath("hidden_weights")
for i = 1:NB_NEURON
    f=open(string("hidden_weights/hidden_weights_", i-1), "w")
    writedlm(f, bits.(hidden_weights[i, :]), "\n")
    close(f)
end

mkpath("output_weights")
for i = 1:NB_OUTPUT
    f=open(string("output_weights/output_weights_", i-1), "w")
    writedlm(f, bits.(output_weights[i, :]), "\n")
    close(f)
end

# show(IOContext(STDOUT, limit=true), "text/plain", hidden_weights)
# print("\n")
# print("\n")
# show(IOContext(STDOUT, limit=true), "text/plain", output_weights)
# print("\n")

close(f)
