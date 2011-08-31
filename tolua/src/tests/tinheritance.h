#include <stdio.h>

class A
{
public:
	A () {}
  virtual ~A() {}
  virtual char* aname () { return "A"; }
	virtual char* name () { return "A"; } 
};

class B : public A
{
public:
	B () {}
  virtual ~B() {}
	virtual char* name () { return "B"; } 
};

class C : public B
{
public:
	C () {}
  virtual ~C() {}
	virtual char* name () { return "C"; } 
};

class D : public C
{
public:
	D () {}
  virtual ~D() {}
	virtual char* name () { return "D"; } 
};

