# Vyn

Vyn is a Lua based programming language, intended for general use, accessability, and and easy learning curve.

> [!IMPORTANT]
> Vyn is currently in it's baby stage; Expect bugs and lack of built in functions.

# Getting Started

## What's Vyn?
Vyn is a Lua based programming language, with easy to use functionality, and was created by Nib Interactive as of Oct. 2025

## Variables
Vyn's variable syntax is different from other languages. It has 3 main types: _Global_, _Local_, & _Private_ types.

**Global** - Written without any keywords, can be called from any other part of the script, even if it was made from a nested block.

```lua
Apples = 5

{ -- Scope Block | Built in scope, used for private variable data, control isolation, etc. Just used as a nested showcase.
  Cars = 17
  print(Apples)
}

print(Cars)
```

**Local** - Written with **local** before the variable name, can be called from any part of the script at the same level environment as it, or nested data inside of the same environment. Unlike globalized variables, it cannot be called from outer blocks.

```lua
local Cartoons = 2 -- Root Level Variable, In this case any part of the script can see it.

{
  local Strength = 150 -- In nested block, cannot be called via outer blocks ^

  print(Cartoons)
}

print(Strength) -- Error: Variable 'Strength' not defined
```

**Private** - Written with **private** before the variable name, similar to local, can be called _only_ from the same block as it. Privates cannot be called from via outer or inner blocks.

```lua
Apples = 4
private Islands = 16

{ -- As this block gets made, it creates a new environment, clearing Islands from the data.
  print(Apples)
  print(Islands) -- Error: Variable 'Islands' not defined
}

print(Islands) -- Error: Variable 'Islands' not defined | Unlike local, private is moreso a temporary variable that gets cleared from the data, unless explicitly recalled using the **datarecall()** function.
```

## Basic Functions
Vyn is loaded when it comes to having built in functions, and uses C in the background for lower ended functions, usually ones talking close/directly to the computer.
Another thing Vyn has going for it is its versatility to multiple iterations. Vyn has multiple ways to code something, wether it be functions, if-statements, etc.

Printing in Vyn is only one of the many things Vyn has going for being universal to other developers.
```lua
print(1 + 7) -- 8 | Can be created with the parenthese
print 1 + 7 -- 8 | Can also be created WITHOUT the parenthese
```

One of Vyn's core takes compared to its competitors, wether it be Rust, C, or anything else, is its interoperable methods of writing code.

```lua
fn add(a + b) {
  return a + b
}
```

As a programmer that switches between many languages, and as many can relate to, having to switch syntax, function names, etc, is actual shit.
Not the code, each one serves me well, but the syntax, just switching on multi-language projects might be the most annoying thing ever, which is why I stick with one when possible.

We had decided to revolutionize that, and gave users the freedom they've always wanted, wether you're a Python user, a C# user, or any other language, we brought ease of use to our language.

```lua
fn add(a, b) {
  return a + b
}

func _Add(a, b):
  return a + b

function Add(y, z)
  return y + z
end
```

The limitations are endless to what Vyn can do, and this is just the surface.

> [!NOTE]
> More Info Via Vyn-0.1.5 to Vyn-0.2