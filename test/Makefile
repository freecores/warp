SOURCES=warptest.v ../rtl/arbiter3.v ../rtl/decay.v ../rtl/fetchsource.v ../rtl/triangleany.v ../rtl/warp.v ../rtl/boundarycheck.v ../rtl/divider10.v ../rtl/pixeladdresses.v ../rtl/triangle.v ../rtl/writedest.v ../rtl/bresenham.v ../rtl/fetchmesh.v ../rtl/roundrobin3.v ../rtl/warpreg.v

all: image.vpi warptest

sim: warptest image.vpi
	vvp -M. -mimage warptest

clean:
	rm -f warptest image.vpi image.o out.png

warptest: $(SOURCES)
	iverilog -o warptest $(SOURCES)

image.vpi: image.c
	iverilog-vpi --name=image image.c -lgd -lpng -lz -ljpeg -lfreetype -lm

.PHONY: clean sim
