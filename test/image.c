/*
 * Testbench for the image warping core (w/o WISHBONE)
 * Copyright (C) 2008 Sebastien Bourdeauducq - http://lekernel.net
 * This file is part of Milkymist.
 *
 * Milkymist is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Library General Public License as published
 * by the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
 * USA.
 */

#include <vpi_user.h>
#include <stdio.h>
#include <gd.h>

static void image_png_register();

void (*vlog_startup_routines[])() = {
	image_png_register,
	0
};

static gdImagePtr src;
static gdImagePtr dst;

/* Open both input and output images */
static int open_calltf(char *user_data)
{
	FILE *fd;

	fd = fopen("in.jpg", "rb");
	src = gdImageCreateFromJpeg(fd);
	fclose(fd);
	
	dst = gdImageCreateTrueColor(src->sx, src->sy);
	return 0;
}

/* Get a pixel from the source image */
static int get_calltf(char *user_data)
{
	vpiHandle sys;
	vpiHandle argv;
	vpiHandle item;
	s_vpi_value value;
	s_vpi_vecval vec;
	unsigned int x, y;
	unsigned int c;
	unsigned int red, green, blue;
	unsigned int r;
	
	sys = vpi_handle(vpiSysTfCall, 0);
	argv = vpi_iterate(vpiArgument, sys);
	
	/* get x */
	item = vpi_scan(argv);
	value.format = vpiIntVal;
	vpi_get_value(item, &value);
	x = value.value.integer;

	/* get y */
	item = vpi_scan(argv);
	value.format = vpiIntVal;
	vpi_get_value(item, &value);
	y = value.value.integer;

	/* do the job */
	c = gdImageGetTrueColorPixel(src, x, y);
	red = gdTrueColorGetRed(c);
	green = gdTrueColorGetGreen(c);
	blue = gdTrueColorGetBlue(c);
	r = (red << 16)|(green << 8)|blue;
	
	/* write to the destination */
	item = vpi_scan(argv);
	value.format = vpiVectorVal;
	vec.aval = r;
	vec.bval = 0;
	value.value.vector = &vec;
	vpi_put_value(item, &value, 0, vpiNoDelay);
	
	vpi_free_object(argv);
	return 0;
}

/* Set a pixel in the destination image */
static int set_calltf(char *user_data)
{
	vpiHandle sys;
	vpiHandle argv;
	vpiHandle item;
	s_vpi_value value;
	s_vpi_vecval vec;
	unsigned int x, y;
	unsigned int c;
	unsigned int red, green, blue;
	unsigned int r;
	
	sys = vpi_handle(vpiSysTfCall, 0);
	argv = vpi_iterate(vpiArgument, sys);
	
	/* get x */
	item = vpi_scan(argv);
	value.format = vpiIntVal;
	vpi_get_value(item, &value);
	x = value.value.integer;

	/* get y */
	item = vpi_scan(argv);
	value.format = vpiIntVal;
	vpi_get_value(item, &value);
	y = value.value.integer;

	/* get color */
	item = vpi_scan(argv);
	value.format = vpiIntVal;
	vpi_get_value(item, &value);
	c = value.value.integer;

	vpi_free_object(argv);

	/* do the job */
	red = (c & 0xFF0000) >> 16;
	green = (c & 0x00FF00) >> 8;
	blue = c & 0x0000FF;
	gdImageSetPixel(dst, x, y,
		gdImageColorAllocate(dst, red, green, blue));
	
	return 0;
}

/* Close both input and output images */
static int close_calltf(char *user_data)
{
	FILE *fd;
	
	gdImageDestroy(src);
	
	fd = fopen("out.png", "wb");
	gdImagePng(dst, fd);
	fclose(fd);
	gdImageDestroy(dst);
	return 0;
}

static void image_png_register()
{
	s_vpi_systf_data tf_data;
	
	tf_data.type      = vpiSysTask;
	tf_data.tfname    = "$image_open";
	tf_data.calltf    = open_calltf;
	tf_data.compiletf = 0;
	tf_data.sizetf    = 0;
	tf_data.user_data = 0;
	vpi_register_systf(&tf_data);
	
	tf_data.type      = vpiSysTask;
	tf_data.tfname    = "$image_get";
	tf_data.calltf    = get_calltf;
	tf_data.compiletf = 0;
	tf_data.sizetf    = 0;
	tf_data.user_data = 0;
	vpi_register_systf(&tf_data);
	
	tf_data.type      = vpiSysTask;
	tf_data.tfname    = "$image_set";
	tf_data.calltf    = set_calltf;
	tf_data.compiletf = 0;
	tf_data.sizetf    = 0;
	tf_data.user_data = 0;
	vpi_register_systf(&tf_data);
	
	tf_data.type      = vpiSysTask;
	tf_data.tfname    = "$image_close";
	tf_data.calltf    = close_calltf;
	tf_data.compiletf = 0;
	tf_data.sizetf    = 0;
	tf_data.user_data = 0;
	vpi_register_systf(&tf_data);
}
