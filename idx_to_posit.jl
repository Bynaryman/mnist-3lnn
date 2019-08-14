import Base.ntoh
import GZip

using SigmoidNumbers

TYPEOUT = Posit{4,0}

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
    return TYPEOUT.((Float16.(contents))./255) 
end

t = readIdx("./train-images-idx3-ubyte.gz")
#print(reinterpret.(UInt, t)[1:4])

# t2 = Array{UInt8}(784*5000) # each uint8 is 2 posit<4,0>
# for i in 1:2:784*10000
#     posit1 = t[i]
#     posit2 = t[i+1]
#     str_bin2posits = string(bits(posit1),bits(posit2))
#     t2[Int((i+1)/2)] = parse(UInt8, str_bin2posits, 2)
# end

# str_bin2posits = ""
# for i in 1:2:784*1
#     posit1 = t[i]
#     posit2 = t[i+1]
#     str_bin2posits = string(str_bin2posits,bits(posit1),bits(posit2), "\n")
# end
# f = open("./posit_mnist_test.raw", "w")
# write(f, str_bin2posits)
# close(f)

# t2 = [parse(UInt8, string("0x",(hex(reinterpret(UInt, x),16)[1:2]))) for x in t]
# res = ""
# for i = 1:2:784
# 	#res = string(res, bits(t[i]), bits(t[i+1]), "\n")
# 	res = string(res, hex(reinterpret(UInt, t[i]),16)[1:4], 
# 		     hex(reinterpret(UInt, t[i+1]),16)[1:4], "\n")
# end
#
#
offset = 1
nb_pics = 128
res = ""
for i = (offset*784)+1:(offset*784)+(784*nb_pics)
	#res = string(res, bits(t[i]), bits(t[i+1]), "\n")
	res = string(res, hex(reinterpret(UInt, t[i]),16)[1:1], "\n")
end

f = open("./pic_to_classify_4b.raw", "w")
write(f, res)
close(f)
# f = open("./posit_mnist_train_set_8b_0es.raw", "w")
# for i in t2
#     write(f, hton(i))
# end
# close(f)

# show(IOContext(STDOUT, limit=true), "text/plain", readIdx("./train-images-idx3-ubyte.gz"))
