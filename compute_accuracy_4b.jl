import Base.ntoh

using SigmoidNumbers

TYPEIN = Posit{4,0}
NB_VALUES = 256
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
# labels = readIdx("./t10k-labels-idx1-ubyte")
#show(IOContext(STDOUT, limit=true), "text/plain", labels)

f = open("./values_posit_out_4b_norm_de_i.raw")
nb_values_to_read = Int64(NB_VALUES*NB_OUT_CLASS/2)

posit_4b_interleave = []
content = read(f, UInt8, nb_values_to_read) # since 1 Byte encodes 2 4b posits
# show(IOContext(STDOUT, limit=false), "text/plain", content)
for i in content
    push!(posit_4b_interleave, TYPEIN(i & 0x0F))
    push!(posit_4b_interleave, TYPEIN((i >> 4) & 0x0F))
    #print(TYPEIN(i & 0x0F)," ", TYPEIN((i>>4) & 0x0f),"\n")
end
#show(IOContext(STDOUT, limit=false), "text/plain", posit_4b_interleave)
#print(size(posit_4b_interleave,1))

float_content = Float64.(TYPEIN.(posit_4b_interleave))
#show(IOContext(STDOUT, limit=true), "text/plain", float_content)
classifications = []

for i in 1:10:size(float_content,1)
	tmp = float_content[i:i+9]
	tmp_max = maximum(tmp)
    if tmp_max == Inf
        push!(classifications, [10])
    else
        positions = [j-1 for(j, x) in enumerate(tmp) if x == tmp_max]
	    push!(classifications, positions)
    end
    #print(tmp_max)
end
close(f)

ok = 0
nok = 0
skiped = 0
#show(IOContext(STDOUT, limit=true), "text/plain", classifications)

for i in 1:256#size(labels,1)
    if classifications[i][1] == 10
        skiped = skiped + 1
    else
        if size(find(classifications[i] .== labels[i]),1) > 0
                ok = ok + 1
	    else
                nok = nok + 1
	    end
    end
end

acc = ok/(ok + nok)*100
print("skiped : ", skiped, "\n")
print("ok : ", ok, "\n")
print("nok : ", nok, "\n")
print("ACCURACY : ", acc, "\n")
