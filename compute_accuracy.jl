import Base.ntoh

using SigmoidNumbers

TYPEIN = Posit{8,0}
NB_VALUES = 60000-32
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

f = open("./classifications_done/mlp30_8_0_nfq_rne_planar.raw")
content = read(f, UInt8, NB_VALUES*NB_OUT_CLASS)
float_content = Float64.(TYPEIN.(content))
#show(IOContext(STDOUT, limit=true), "text/plain", float_content)
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

for i in 1:NB_VALUES
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
