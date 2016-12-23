; RUN: llc < %s -march=x86 -mcpu=core2 -no-integrated-as | FileCheck %s

define i32 @t1() nounwind {
entry:
  %0 = tail call i32 asm sideeffect inteldialect "mov eax, $1\0A\09mov $0, eax", "=r,r,~{eax},~{dirflag},~{fpsr},~{flags}"(i32 1) nounwind
  ret i32 %0
; CHECK: t1
; CHECK: {{## InlineAsm Start|#APP}}
; CHECK: .intel_syntax
; CHECK: mov eax, ecx
; CHECK: mov ecx, eax
; CHECK: .att_syntax
; CHECK: {{## InlineAsm End|#NO_APP}}
}

define void @t2() nounwind {
entry:
  call void asm sideeffect inteldialect "mov eax, $$1", "~{eax},~{dirflag},~{fpsr},~{flags}"() nounwind
  ret void
; CHECK: t2
; CHECK: {{## InlineAsm Start|#APP}}
; CHECK: .intel_syntax
; CHECK: mov eax, 1
; CHECK: .att_syntax
; CHECK: {{## InlineAsm End|#NO_APP}}
}

define void @t3(i32 %V) nounwind {
entry:
  %V.addr = alloca i32, align 4
  store i32 %V, i32* %V.addr, align 4
  call void asm sideeffect inteldialect "mov eax, DWORD PTR [$0]", "*m,~{eax},~{dirflag},~{fpsr},~{flags}"(i32* %V.addr) nounwind
  ret void
; CHECK: t3
; CHECK: {{## InlineAsm Start|#APP}}
; CHECK: .intel_syntax
; CHECK: mov eax, DWORD PTR {{[[esp]}}
; CHECK: .att_syntax
; CHECK: {{## InlineAsm End|#NO_APP}}
}

%struct.t18_type = type { i32, i32 }

define i32 @t18() nounwind {
entry:
  %foo = alloca %struct.t18_type, align 4
  %a = getelementptr inbounds %struct.t18_type* %foo, i32 0, i32 0
  store i32 1, i32* %a, align 4
  %b = getelementptr inbounds %struct.t18_type* %foo, i32 0, i32 1
  store i32 2, i32* %b, align 4
  call void asm sideeffect inteldialect "lea ebx, foo\0A\09mov eax, [ebx].0\0A\09mov [ebx].4, ecx", "~{eax},~{dirflag},~{fpsr},~{flags}"() nounwind
  %b1 = getelementptr inbounds %struct.t18_type* %foo, i32 0, i32 1
  %0 = load i32* %b1, align 4
  ret i32 %0
; CHECK: t18
; CHECK: {{## InlineAsm Start|#APP}}
; CHECK: .intel_syntax
; CHECK: lea ebx, foo
; CHECK: mov eax, [ebx].0
; CHECK: mov [ebx].4, ecx
; CHECK: .att_syntax
; CHECK: {{## InlineAsm End|#NO_APP}}
}

define void @t19_helper() nounwind {
entry:
  ret void
}

define void @t19() nounwind {
entry:
  call void asm sideeffect inteldialect "call $0", "r,~{dirflag},~{fpsr},~{flags}"(void ()* @t19_helper) nounwind
  ret void
; CHECK-LABEL: t19:
; CHECK: movl ${{_?}}t19_helper, %eax
; CHECK: {{## InlineAsm Start|#APP}}
; CHECK: .intel_syntax
; CHECK: call eax
; CHECK: .att_syntax
; CHECK: {{## InlineAsm End|#NO_APP}}
}

@results = global [2 x i32] [i32 3, i32 2], align 4

define i32* @t30() nounwind ssp {
entry:
  %res = alloca i32*, align 4
  call void asm sideeffect inteldialect "lea edi, dword ptr $0", "*m,~{edi},~{dirflag},~{fpsr},~{flags}"([2 x i32]* @results) nounwind
  call void asm sideeffect inteldialect "mov dword ptr $0, edi", "=*m,~{dirflag},~{fpsr},~{flags}"(i32** %res) nounwind
  %0 = load i32** %res, align 4
  ret i32* %0
; CHECK-LABEL: t30:
; CHECK: {{## InlineAsm Start|#APP}}
; CHECK: .intel_syntax
; CHECK: lea edi, dword ptr [{{_?}}results]
; CHECK: .att_syntax
; CHECK: {{## InlineAsm End|#NO_APP}}
; CHECK: {{## InlineAsm Start|#APP}}
; CHECK: .intel_syntax
; CHECK: mov dword ptr [esp], edi
; CHECK: .att_syntax
; CHECK: {{## InlineAsm End|#NO_APP}}
; CHECK: movl (%esp), %eax
}

; Stack realignment plus MS inline asm that does *not* adjust the stack is no
; longer an error.

define i32 @t31() {
entry:
  %val = alloca i32, align 64
  store i32 -1, i32* %val, align 64
  call void asm sideeffect inteldialect "mov dword ptr $0, esp", "=*m,~{dirflag},~{fpsr},~{flags}"(i32* %val) #1
  %sp = load i32* %val, align 64
  ret i32 %sp
; CHECK-LABEL: t31:
; CHECK: pushl %ebp
; CHECK: movl %esp, %ebp
; CHECK: andl $-64, %esp
; CHECK: {{## InlineAsm Start|#APP}}
; CHECK: .intel_syntax
; CHECK: mov dword ptr [esp], esp
; CHECK: .att_syntax
; CHECK: {{## InlineAsm End|#NO_APP}}
; CHECK: movl (%esp), %eax
; CHECK: ret
}
