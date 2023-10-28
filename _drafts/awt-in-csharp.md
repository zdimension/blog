---
title: 'Using AWT in C#'
excerpt: "A story of how Microsoft ported Java to .NET and accidentally created Windows Forms in the process, only to throw it away and pretend it never happened."
category: "Long posts"
tags: [Programming, History]
---

> If you don't care about the "History" part, you can skip directly to the 

## A bit of history

In the late 90s, Microsoft started working on a development platform supposed to replace COM, which was back then an absolute behemoth in the world of Windows programming: everything new was being built on top of COM. Office? That's OLE, just COM with more spaz. VB6? Just COM libraries. New Windows components all got their own shiny COM interfaces. It worked so well even Apple used it (a bit). 

That said, writing in C or C++ was still a pain, and VB6 still had some kind of "toy language" connotation to it -- sure, it was good, second to only Delphi in terms of fast GUI development ("RAD"), but it was still far from what Sun had been offering for a few years with their amazing new "Java" platform. It lacked true OOP, 

Java, you say? That "*write once, run anywhere*" thing? That's a problem for Microsoft. If I can run my corporate app anywhere, why would I pay for a Windows license? 

Microsoft, deep down, was born as a *development tools* company. Sure, they ended up buying IP here and there and sold [an operating system](https://github.com/microsoft/MS-DOS) to IBM in the 80s, but they still started by selling BASIC interpreters for 8-bit CPUs. 

The most important part of an operating system is the ecosystem. People want to use their computers to do stuff, and for that they need apps, and these apps need to have been written by someone. If it's hard to write apps for your platform, developers will flee to the competition and your platform will die.

> Except, of course, if you *know* your platform will succeed, and developers know it too. The most famous example of a hard-to-write-software-for platform for which a lot of software got written is Sony's PlayStation 3. Its CPU, however powerful it was, was all but idiosyncratic. It was really hard to write efficient code for it, but game developers still did it, because it was the PS3.
{: .prompt-tip }

Operating systems have some kind of inherent inertia. Computers are shipped with an OS, and the vast majority of people either don't want to use another OS or simply don't know that they can, and they end up just using whatever's installed out of the box, and for most personal computers, even back then, that's Windows. Tben, once you've spent a few years getting comfortable with that, when it's time to upgradew you tend to choose the next version of the same OS, because that's what you're most familiar with. Meanwhile, software developers wrote their software in the hope of selling it, so it's in their advantage to write it for well-known OSes. And having software available for one OS is an incentive for people to use it. Getting the world to change their OS is hard, because you have a dozen virtuous circles to break.

Hard, but not impossible. If people start writing their software in a language that works everywhere, then that's less and less of an incentive to stay on whatever OS you're using. Java, in the 90s, was a threat to Microsoft and Windows's monopoly on business computing.

### Redmond fights back: Visual J++ and MSJVM

Microsoft's first attempt to counter Sun was in the form of Visual J++, which was nothing more than a licensed implementation of Java and the JVM. It ended with Sun suing Microsoft about it and the whole product was litigated out of existence because it was not compliant enough with the Java specs, so Sun forbid Microsoft from selling anything with the name "Java" on it.

J++ had something that Java was missing, however: the ability to use the Win32 APIs in a clean, object-oriented, managed way. These APIs were exposed under the name "Windows Foundation Classes", which should remind you of the "Microsoft Foundation Classes", the well-known C++ library-set/framework for writing Windows apps. 

The year is 1996, and this is real code:

```java
import com.ms.wfc.app.*;
import com.ms.wfc.core.*;
import com.ms.wfc.ui.*;

public class HelloWorld extends Form
{
    public HelloWorld()
    {
        super();
        setText("Hello World");
        setAutoScaleBaseSize(new Point(5, 13));
        setClientSize(new Point(292, 266));
        MessageBox::show("Hello World", "Hello World");
    }

    public static void main(String args[])
    {
        Application.run(new HelloWorld());
    }
}
```

If it looks like Windows Forms... it's because it is. Or rather, it will be, in a few years.

In parallel, what would later become .NET was still brewing. The VB development team had been working for some time on something called the "Common Object Runtime". It walked like COM and quacked like COM, but it was *really* object-oriented, and had proper garbage collection. Later, this would become the CLR, or "Common Language Runtime". The original name ("COR") persists in the name of one of the main assemblies used in .NET today, `mscorlib.dll`.

On top of that runtime, a language was being developed. It was internally called "Cool" ([even though Microsoft denied it](https://www.itwriting.com/blog/381-how-aspnet-began-in-java-and-the-truth-about-project-cool.html)), and it was a statically-typed, object-oriented language with a C-like syntax. If that sounds suspiciously like Java, that's because it pretty much was. Anders Hejlsberg, who'd previously worked on Object Pascal at Borland, and was one of the main designers of aforementioned J++ and WFC, was the lead architect of "Cool". [He's good at making languages and stuff](https://www.typescriptlang.org/).

I won't go too much in the details of .NET and C# themselves, because it's not the topic, and this chapter is already way too long.

### Visual J#

After Microsoft was forced by Sun to stop using Java, they had a problem: sure, .NET sold, and C# was nice, but for a lot of Java users it wasn't enough to warrant a switch. They needed a way to get Java developers to use .NET, and they needed it fast.

And fast they got it: in October of 2001, the first beta version of Visual J# (codenamed ["Banjara"](https://web.archive.org/web/20021129144224/http://discuss.develop.com/archives/wa.exe?A2=ind0110A&L=DOTNET&D=0&P=59113)) was uploaded to MSDN. Webloggers of the time were quick to [check it out](https://web.archive.org/web/20020201183211/http://www.oreillynet.com/cs/weblog/view/wlg/748).

There they had it: Java, running on the CLR. You wrote [regular-ass](https://xkcd.com/37/) Java code and it would get compiled to CIL code and run on the CLR virtual machine, effortlessly referencing other CLR assemblies written in C# or VB.NET.

This lasted for a few years, until Microsoft deprecated it around 2007-08 and now you'd be hard-pressed to find anything referencing it. There are still bits of documentation laying around on MSDN, but apart from that, your best bet is archive.org.

There is a caveat: J# targets .NET, which includes the .NET standard library. Java has its own standard library -- `System.out.println` has to come from somewhere. Which means... J# includes its own implementation of the Java standard library APIs. As CLR assemblies.

## Let's use Java from C#

Under the right conditions (.NET Framework, no .NET Core), if you reference the vjslib.dll assembly from the Visual J# files, the following C# code works:

```csharp
class Program
{
    static void Main()
    {
        java.lang.System.@out.println("Hello World");
    }
}
```

Obviously, it also works in VB:

```vb
Module Module1

    Sub Main()
        java.lang.System.out.println("Hello World")
    End Sub

End Module
```