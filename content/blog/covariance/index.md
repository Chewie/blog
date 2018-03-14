---
title: "On covariance and C++ templates"
date: 2013-02-10T11:22:09+01:00
comments: true
---

# Introduction

This rather short post is a quick overview of an intermediate concept in C++
and basic type theory. You probably won't find great value in it if you're a
programming guru.

# Variance?

During your developer adventures, you may have encountered a few words that
made you scratch your head. Perhaps you've read that C++ pointers are
*covariant*, or that C# 4 added support for *contravariant* delegates. But what
does it mean?

Suppose we have a type T, and a type S which is a subtype of T. This relation is
usually represented like so : *S <: T*. This is what happens when you use
inheritance in most modern object oriented languages:

{{< highlight cpp >}}
// We have a base class, the "supertype"
class Animal {};

// We derive that class in a subtype
class Cat : public Animal {};
{{< /highlight >}}

In this C++ example, we have the following relationship : `Cat <: Animal`. That
is, Cat is a subtype of Animal.
Note that some languages like OCaml [don't
associate inheritance with
subtyping](http://caml.inria.fr/pub/docs/oreilly-book/html/book-ora144.html#toc212),
this is a case of *structural typing*, as opposed to the *nominative typing*
we're studying right now.

Now, let's suppose we have some sort of function that takes a type, and creates
a new type based on it. This can happen in a multitude of scenarii: adding
constness (from `Cat` to `const Cat`), pointerness (`Cat` to `Cat*`), creating
an array of that type (`Cat` to `Cat[]`)... You get the idea. Just for the sake
of this explanation, imagine an operation of this kind is made by a function F,
which can be applied to a type. The notation, obviously, would be this : `F(T)`.

Let's go back to the relationship we created above: `S <: T`. The question is,
what happens to this relationship if both S and T go through the F machine?

* If the relationship is preserved, that is `F(S) <: F(T)`, then F is said to
  be *covariant*.

* If the relationship is reversed, that is `F(T) <: F(S)`, then F is said to be
  *contravariant*.

* Lastly, if the machine destroyed the relationship, then F is *invariant*:
  **both** `F(S) <: F(T)` and `F(T) <: F(S)` are false


Let's have a few examples, shall we?

## C++ pointers

C++ pointers are covariant. This means that if `Cat <: Animal`, then
`Cat* <: Animal*`. That's what allows us to substitute an `Animal*` for a
`Cat*` or a `Dog*`, hence achieving polymorphism.

Note that this is also because of this that `void*` lost the magical
polymorphic property it had in C: if any pointer type can be converted to
`void*`, and that `void*` can in turn be converted to any other pointer type,
then void would need to both be a subtype _and_ a supertype of every other type
in the system, which would be quite silly, if you ask me.

{{< figure src="silly.jpg" caption="Silly, you say? Get on with it!" class="text-center" >}}

## C++ Templates

Templates in C++ are invariant, and for a good reason!
Imagine they were covariant, what would that mean?
Let's go back to our pet shop, and try to put them in std::vectors :

{{< highlight cpp >}}
int main()
{
    std::vector<Cat*> v1;
    v1.push_back(new Cat);

    // Now if vector was covariant, we could cast v1 like so.
    // Note the offending '&'
    std::vector<Animal*>& v2 = v1;

    // Dogs and cats living together... mass hysteria!
    v2.push_back(new Dog);
}
{{< /highlight >}}

Clearly, this behavior is not desirable, so templates are understandably
invariant.

# But what about smart pointers?

If you've been following carefully, something may have intrigued you: what
about smart pointers?

Quick reminders: a smart pointer is a templated class that encapsulates a
pointer and provides additionnal features, like automatic deletion upon leaving
the scope. As such, they mimick as closely as possible the behaviour and
characteristics of pointers, and covariance should be one of them.

Indeed, what use would be a pointer that couldn't do the following?

{{< highlight cpp >}}
int main()
{
    std::vector<Animal*> v;

    // These actions work because pointers are covariant
    v.push_back(new Cat);
    v.push_back(new Dog);

    // Now Imagine an invariant smart pointer, BadPointer:
    std::vector<BadPointer<Animal>> v2;

    // BadPointer<Animal> and BadPointer<Cat> are completely unrelated
    // types, so these won't work:
    v2.push_back(BadPointer<Cat>(new Cat));
    v2.push_back(BadPointer<Dog>(new Dog));

    // Yet we can do that with a properly implemented smart pointer:
    std::vector<std::shared_ptr<Animal>> v3;

    // It works, hurray!
    v3.push_back(std::make_shared<Cat>());
    v3.push_back(std::make_shared<Dog>());
}
{{< /highlight >}}

So shared pointers correctly mimick covariance... but *how do they do that?*

The trick is actually quite simple: we just have to parametrize the copy
constructors and the assignment operator with a generic type:

{{< highlight cpp >}}
template <typename T>
class SmartPointer
{
public:
    // Nothing special here, move along
    SmartPointer(T* p) : p_(p) {}
    SmartPointer(const SmartPointer& sp) : p_(sp.p_) {}
    SmartPointer& operator=(const SmartPointer& sp)
    {
        p_ = sp.p_;
    }

    // Now this is more like it!
    template <typename U>
    SmartPointer(U* p) : p_(p) {}

    // Wash, rince, repeat
    template <typename U>
    SmartPointer(const SmartPointer<U>& sp) : p_(sp.p_) {}

    // And finally
    template <typename U>
    SmartPointer<T>& operator=(const SmartPointer<U>& sp)
    {
        p_ = sp.p_;
    }

private:
   T* p_;
};
{{< /highlight >}}

Since template parameters work with any type, provided it doesn't generate an
error, the validity of these operations is deferred to the pointer
manipulation, which works as intended.


I think I covered most of the things that needed to be said, so I'll wrap it up
here. Have a good night, and dream of happy little pointers.

