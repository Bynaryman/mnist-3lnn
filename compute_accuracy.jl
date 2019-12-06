import Base.ntoh
using SigmoidNumbers

# ARGS[1] : POSIT_WIDTH
# ARGS[2] : input path of planar classifications

POSIT_WIDTH = parse(UInt64,ARGS[1])
TYPEIN = Posit{POSIT_WIDTH,0}
MNIST_TRAIN_SIZE = 60000
CHUNK_WIDTH = (64÷POSIT_WIDTH) * 8
REMOVED_PICTURES = MNIST_TRAIN_SIZE % CHUNK_WIDTH 
NB_PICTURES = MNIST_TRAIN_SIZE-REMOVED_PICTURES
NB_POSITS_IN_64b = 64 ÷ POSIT_WIDTH
NB_VALUES = (NB_PICTURES*8)÷NB_POSITS_IN_64b 
NB_OUT_CLASS = 10

function readIdx(file_name)
    fs = open(file_name, "r")
    magic_number = read(fs, UInt8, 4)
    if magic_number[3] == 0x08
        idx_type = UInt8
    elseif magic_number[2] == 0x09
        idx_type = Int8
    elseif magic_number[2] == 0x0B
        idx_type = Int16
    elseif magic_number[2] == 0x0C
        idx_type = Int32
    elseif magic_number[2] == 0x0D
        idx_type = Float32
    elseif magic_number[2] == 0x0E
        idx_type = Float64
    end

    dims = Array{Int64}(ntoh.(read(fs, Int32, magic_number[4])))
    contents = read(fs, idx_type, prod(dims))
    if idx_type != UInt8 && idx_type != Int8
        contents = ntoh.(contents)
    end
    
    close(fs)
    return contents
end

labels = readIdx("./train-labels-idx1-ubyte")
#show(IOContext(STDOUT, limit=true), "text/plain", t)
nb_values_to_read = Int64((NB_VALUES*NB_OUT_CLASS)/8)
# read file planar serial classifications as Bytes
f = open(ARGS[2])
file_content = read(f, UInt64, nb_values_to_read)
#show(IOContext(STDOUT, limit=true), "text/plain", file_content)

# perform conversion to POSIT_TYPE
posits_scrathpad = []
MASK = ((2^POSIT_WIDTH)-1)
for i in file_content
    for j in 0:(NB_POSITS_IN_64b-1)
        ptmp = (i >> (j*POSIT_WIDTH)) & MASK
        push!(posits_scrathpad, TYPEIN(ptmp))
    end
end

#show(IOContext(STDOUT, limit=true), "text/plain", posits_scrathpad)

# compute classification
float_content = Float64.(posits_scrathpad)
classifications = []
for i in 1:10:size(float_content,1)
	tmp = float_content[i:i+9]
	tmp_max = maximum(tmp)
	positions = [j-1 for(j, x) in enumerate(tmp) if x == tmp_max]
	push!(classifications, positions)
end
close(f)

ok = 0
nok = 0

for i in 1:NB_PICTURES
	if size(find(classifications[i] .== labels[i]),1) > 0
            ok = ok + 1
	else
            nok = nok + 1
	end
end

acc = ok/(ok + nok)*100
print("ok : ", ok, "\n")
print("nok : ", nok, "\n")
print("TOP 1 ACCURACY : ", acc, "\n")
