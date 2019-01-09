import Base.ntoh
import GZip

using SigmoidNumbers

TYPEOUT = Posit{16,0}

function readIdx(file_name)
    fs = GZip.open(file_name, "r")
    magic_number = read(fs, UInt8, 4)
    print(magic_number)
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

    dims_tmp = Array{Int64}(ntoh.(read(fs, Int32, magic_number[4])))
    dims = [dims_tmp[2], dims_tmp[3], dims_tmp[1]]
    contents = read(fs, idx_type, prod(dims))
    if idx_type != UInt8 && idx_type != Int8
        contents = ntoh.(contents)
    end
    
    close(fs)
    return TYPEOUT.(Float16.(contents)) 
end

t = readIdx("./train-images-idx3-ubyte.gz")
print(size(t)[1])
res = ""
for i = 1:2:784
	#res = string(res, bits(t[i]), bits(t[i+1]), "\n")
	res = string(res, hex(reinterpret(UInt, t[i]),16)[1:4], 
		     hex(reinterpret(UInt, t[i+1]),16)[1:4], "\n")
end

f = open("./posit_mnist.raw", "w")
write(f, res)
close(f)


# show(IOContext(STDOUT, limit=true), "text/plain", readIdx("./train-images-idx3-ubyte.gz"))
