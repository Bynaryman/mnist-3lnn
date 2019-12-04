import Base.ntoh
import GZip

using SigmoidNumbers

POSIT_OUT_WIDTH = parse(UInt,ARGS[1])
TYPEOUT = Posit{POSIT_OUT_WIDTH,0}
mask = UInt64((2^POSIT_OUT_WIDTH)-1)
mask <<= (64-POSIT_OUT_WIDTH)

function readIdx(file_name)
    fs = GZip.open(file_name, "r")
    magic_number = read(fs, UInt8, 4)
    # print(magic_number)
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
#show(IOContext(STDOUT, limit=false), "text/plain", t[1:784])
#print(reinterpret.(UInt, t)[1:4])

# t2 = Array{UInt8}(784*5000) # each uint8 is 2 posit<4,0>
# for i in 1:2:784*10000
#     posit1 = t[i]
#     posit2 = t[i+1]
#     str_bin2posits = string(bits(posit1),bits(posit2))
#     t2[Int((i+1)/2)] = parse(UInt8, str_bin2posits, 2)
# end
# f = open("./posit_mnist_train_set_8b_0es.raw", "w")
# for i in t2
#     write(f, hton(i))
# end
# close(f)

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



# to create test bench 4 bits
# offset = 0
# nb_pics = 128
# res = ""
# for i = (offset*784)+1:(offset*784)+(784*nb_pics)
# 	#res = string(res, bits(t[i]), bits(t[i+1]), "\n")
# 	res = string(res, hex(reinterpret(UInt, t[i]),16)[1:1], "\n")
# end
# f = open("./pic_to_classify_4b.raw", "w")
# write(f, res)
# close(f)
# to create mnist 4 bits
# f = open("./pic_to_classify_4b.raw", "w")
NB_MLP_PER_512b_BUS = (512÷POSIT_OUT_WIDTH)
print("NB_MLP HW per 512b bus: ", NB_MLP_PER_512b_BUS, "\n")
removed_pictures = 60000 % NB_MLP_PER_512b_BUS
print("removed pictures: ", removed_pictures, "\n")
str_fileout = string("mnist_normalized-", removed_pictures, "pic", "_", POSIT_OUT_WIDTH, "b.raw")
f = open(str_fileout, "w")
nb_posits_in64bp = 64 ÷ POSIT_OUT_WIDTH
a = 0
for i in 1:(nb_posits_in64bp):(size(t,1)-removed_pictures*784)
    posits_concatened_64b = UInt64(0x0000000000000000)
    it = 1
    for j in i:(i+nb_posits_in64bp-1)
        # print(hex(reinterpret(UInt, t[j  ]),16), "\n")
        a1 = ((parse(UInt, hex(reinterpret(UInt, t[j  ])),16)) & (mask))>> (64 - (it*POSIT_OUT_WIDTH))
        # if j < 784
        #     print(t[j], " " )
        #     print(((parse(UInt, hex(reinterpret(UInt, t[j  ])),16)) & (0xfc00000000000000)), " ")
        #     print(it , " ")
        #     print(((parse(UInt, hex(reinterpret(UInt, t[j  ])),16)) & (0xfc00000000000000)) >> (64 - (it*POSIT_OUT_WIDTH)), " ")
        #     print("A1=", a1 , "  ")
        # end
        #print(a1, "\n")
        it = it+1
        posits_concatened_64b |= a1
        # print("concat" , posits_concatened_64b, "\n")
        #print(posits_concatened_64b, "\n")
        #a1 = reinterpret(UInt, t[i  ])
        #a2 = reinterpret(UInt, t[i+1])
    a = a+1
    end
    write(f, posits_concatened_64b)
    # if i<1000
    #     print(bin(posits_concatened_64b), "\n")
    # end
end
close(f)

# show(IOContext(STDOUT, limit=true), "text/plain", readIdx("./train-images-idx3-ubyte.gz"))
