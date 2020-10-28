#!/bin/bash

fun1()
{
	caller 0
}
fun2()
{
	fun1
}

fun2

exit 0
