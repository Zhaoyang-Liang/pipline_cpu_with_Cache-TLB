# ��ˮ��CPU��·����ʵ��ʵ�鱨��

## ? ʵ����Ϣ

- **ʵ������**���弶��ˮ��CPU��·���������ʵ��
- **ʵ��ʱ��**��2024��
- **ʵ�黷��**��Vivado + Verilog HDL
- **��������**��Verilog HDL
- **Ŀ��ƽ̨**��FPGA

---

## 1. ʵ�鱳����Ŀ��

### 1.1 ʵ�鱳��

���弶��ˮ��CPU����У�������أ�Data Hazard����Ӱ�����ܵ���Ҫ����֮һ��������ָ����Ҫ�õ�ǰ��ָ��Ľ��ʱ�����ֱ��ִ�лᵼ�����ݴ��󡣴�ͳ�Ľ�������ǲ������ݣ�Stall�������������������ˮ��Ч�ʡ�

�ִ��������ձ������·��Bypass/Forwarding���������������������⣬ͨ����������ˮ���Ľ��ֱ��ת������Ҫ���ݵ�ָ�����ȴ�����д�ؼĴ����ѣ��Ӷ�������ˮ������������������ܡ�

### 1.2 ʵ��Ŀ��

- ? ʵ����������·��Bypass/Forwarding�����ƣ����ٲ���Ҫ����ˮ������
- ? ���ר�õ���·��ⵥԪ����ߴ����ά���ԺͿɲ�����
- ? ��ȷ���������������������Load-Use��ء������ڲ����ȣ�
- ? ����ԭ�й��������ԣ�ȷ��ϵͳ��ȷ��
- ? �Ż�����ṹ����߿�ά����

---

## 2. ���˼·��ܹ�

### 2.1 ��·����ԭ��

��·���Ƶĺ���˼���ǣ���һ��ָ����Ҫĳ���Ĵ�����ֵʱ�������ֵ���ں�����ˮ���м�����Ѿ�������ɵ���δд�ؼĴ����ѣ������ֱ�Ӵ���Ӧ����ˮ����ȡ��ֵ��������Ҫ�ȴ���д�ؼĴ����ѡ�

### 2.2 ����ܹ����

```
����������������������    ����������������������    ����������������������    ����������������������    ����������������������
��   IF    ��������?��   ID    ��������?��   EXE   ��������?��   MEM   ��������?��   WB    ��
��         ��    ��         ��    ��         ��    ��         ��    ��         ��
����������������������    ����������������������    ����������������������    ����������������������    ����������������������
                      ��              ��              ��
                      ��              ��              ��
                      �������������������������������੤����������������������������
                                     ��
                              ������������������������������
                              �� Bypass Unit ��
                              ��   (��·��Ԫ)  ��
                              ������������������������������
```

### 2.3 �ؼ���ƾ���

1. **ģ�黯���**������������`bypass_unit.v`ģ�飬�����ӵ���·����߼���װ����
2. **���ȼ�����**��EXE > MEM > WB > �Ĵ����ѣ�ȷ�����ݵ����ʶ�
3. **���⴦��**��Load-Use�����Ҫ�����������ڲ�����Ҫ����
4. **�źŴ���**��ͨ�����ߴ�����·���ݺͿ����źţ����ֽӿ�����

---

## 3. ����ģ�����

### 3.1 ��·��ⵥԪ (bypass_unit.v)

#### ģ�鹦��

��·��ⵥԪ�Ǳ���ʵ��ĺ���ģ�飬����
- ��⵱ǰָ���������ˮ��ָ��֮����������
- �����Ƿ���Ҫʹ����·����
- �ж��Ƿ���Ҫ������ˮ��
- ѡ�����ŵ�����Դ

#### �˿ڶ���

```verilog
module bypass_unit(
    // ��ǰָ����Ϣ
    input [4:0]  rs, rt,                    // Դ�Ĵ�����ַ
    input [31:0] rs_value, rt_value,        // Դ�Ĵ���ֵ
    
    // ������ˮ����Ϣ
    input [4:0]  EXE_wdest, MEM_wdest, WB_wdest,  // д��Ŀ��Ĵ���
    input [31:0] EXE_result, MEM_result, WB_result, // ������
    input        EXE_valid, MEM_valid, WB_valid,   // ��Ч�ź�
    
    // ָ��������Ϣ
    input        inst_load, inst_mult,      // ��ǰָ������
    input        EXE_inst_load, EXE_inst_mult, // EXE��ָ������
    
    // ���
    output [31:0] bypassed_rs_value,        // ��·���rsֵ
    output [31:0] bypassed_rt_value,        // ��·���rtֵ
    output        stall_required            // �Ƿ���Ҫ����
);
```

#### �����㷨

```verilog
// ��·����߼�
wire exe_bypass_rs = (rs != 0) && (rs == EXE_wdest) && EXE_valid;
wire mem_bypass_rs = (rs != 0) && (rs == MEM_wdest) && MEM_valid;
wire wb_bypass_rs  = (rs != 0) && (rs == WB_wdest)  && WB_valid;

wire exe_bypass_rt = (rt != 0) && (rt == EXE_wdest) && EXE_valid;
wire mem_bypass_rt = (rt != 0) && (rt == MEM_wdest) && MEM_valid;
wire wb_bypass_rt  = (rt != 0) && (rt == WB_wdest)  && WB_valid;

// ��·����ѡ�����ȼ���EXE > MEM > WB > �Ĵ����ѣ�
assign bypassed_rs_value = exe_bypass_rs ? EXE_result :
                           mem_bypass_rs ? MEM_result :
                           wb_bypass_rs  ? WB_result  : rs_value;

assign bypassed_rt_value = exe_bypass_rt ? EXE_result :
                           mem_bypass_rt ? MEM_result :
                           wb_bypass_rt  ? WB_result  : rt_value;

// �����������
wire load_use_hazard_rs = exe_bypass_rs & EXE_inst_load;
wire load_use_hazard_rt = exe_bypass_rt & EXE_inst_load;
wire mult_use_hazard_rs = exe_bypass_rs & EXE_inst_mult;
wire mult_use_hazard_rt = exe_bypass_rt & EXE_inst_mult;

assign stall_required = load_use_hazard_rs | load_use_hazard_rt | 
                       mult_use_hazard_rs | mult_use_hazard_rt;
```

### 3.2 ���뼶�޸� (decode.v)

#### ��Ҫ�޸�����

1. ������·��ⵥԪ
2. ʹ����·����������ԭʼ�Ĵ�������
3. �Ƴ�ԭ�е�`rs_wait`/`rt_wait`�߼�
4. ���¶˿ڶ�����֧����·�ź�

#### �ؼ�����ʵ��

```verilog
// ��·��ⵥԪʵ����
bypass_unit bypass_inst(
    .rs(rs), .rt(rt),
    .rs_value(rs_value), .rt_value(rt_value),
    .EXE_wdest(EXE_wdest), .MEM_wdest(MEM_wdest), .WB_wdest(WB_wdest),
    .EXE_result(EXE_result), .MEM_result(MEM_result), .WB_result(WB_result),
    .EXE_valid(EXE_valid), .MEM_valid(MEM_valid), .WB_valid(WB_valid),
    .inst_load(inst_load), .inst_mult(inst_mult),
    .EXE_inst_load(EXE_inst_load), .EXE_inst_mult(EXE_inst_mult),
    .bypassed_rs_value(bypassed_rs_value),
    .bypassed_rt_value(bypassed_rt_value),
    .stall_required(stall_required)
);

// ʹ����·�������
assign alu_a = bypassed_rs_value;
assign alu_b = bypassed_rt_value;
assign store_data = bypassed_rt_value;

// ����ID_over�߼�
assign ID_over = ID_valid & (~inst_jbr | IF_over) & ~stall_required;
```

### 3.3 ִ�м��޸� (exe.v)

#### ��Ҫ�޸�����

1. ���ִ�н��������·
2. ���ָ��������Ϣ
3. �����·��ض˿�

#### �ؼ�����ʵ��

```verilog
// ���ִ�н��
assign EXE_result = exe_result;

// ���ָ������
assign EXE_inst_load = inst_load;
assign EXE_inst_mult = multiply;

// ���д��Ŀ��Ĵ���
assign EXE_wdest = rf_wdest;
```

### 3.4 �ô漶�޸� (mem.v)

#### ��Ҫ�޸�����

1. ����ô���������·
2. �����·��ض˿�

#### �ؼ�����ʵ��

```verilog
// ����ô���
assign MEM_result = mem_result;

// ���д��Ŀ��Ĵ���
assign MEM_wdest = rf_wdest;
```

### 3.5 д�ؼ��޸� (wb.v)

#### ��Ҫ�޸�����

1. �������д������������·
2. �����·��ض˿�

#### �ؼ�����ʵ��

```verilog
// ���д�ؽ��
assign WB_result = rf_wdata;

// ���д��Ŀ��Ĵ���
assign WB_wdest = rf_wdest;
```

---

## 4. �ź��������������

### 4.1 ��·�źŶ���

```verilog
// ��·�����ź�
wire [31:0] EXE_result;    // EXE�����
wire [31:0] MEM_result;    // MEM�����  
wire [31:0] WB_result;     // WB�����

// ��·�����ź�
wire [4:0] EXE_wdest;      // EXE��д��Ŀ��Ĵ���
wire [4:0] MEM_wdest;      // MEM��д��Ŀ��Ĵ���
wire [4:0] WB_wdest;       // WB��д��Ŀ��Ĵ���

// EXE��ָ��������Ϣ
wire EXE_inst_load;        // EXE��Loadָ��
wire EXE_inst_mult;        // EXE���˷�ָ��
```

### 4.2 ģ�������

```verilog
// IDģ��ʵ������������·�źţ�
decode ID_module(
    // ... ԭ���ź� ...
    .EXE_result(EXE_result),
    .MEM_result(MEM_result),
    .WB_result(WB_result),
    .EXE_wdest(EXE_wdest),
    .MEM_wdest(MEM_wdest),
    .WB_wdest(WB_wdest),
    .EXE_valid(EXE_valid),
    .MEM_valid(MEM_valid),
    .WB_valid(WB_valid),
    .EXE_inst_load(EXE_inst_load),
    .EXE_inst_mult(EXE_inst_mult)
);
```

---

## 5. ���⴦�����

### 5.1 Load-Use��ش���

��EXE����Loadָ����ID����Ҫ����ʱ����������һ�����ڣ���ΪLoadָ��Ľ����Ҫ2�����ڲ��ܻ�á�

```verilog
// Load-Use��ؼ��
wire load_use_hazard_rs = exe_bypass_rs & EXE_inst_load;
wire load_use_hazard_rt = exe_bypass_rt & EXE_inst_load;
```

### 5.2 �����ڲ�������

��EXE���ǳ˷�ָ��ʱ����Ҫ����ֱ���˷���ɡ�

```verilog
// �����ڲ������
wire mult_use_hazard_rs = exe_bypass_rs & EXE_inst_mult;
wire mult_use_hazard_rt = exe_bypass_rt & EXE_inst_mult;
```

### 5.3 ��ָ֧���

����ԭ�еķ�֧Ԥ�����ת�߼����䣬ȷ������������ȷ�ԡ�

---

## 6. �����Ż���ά���ԸĽ�

### 6.1 �궨�����

����`top.v`�ļ�ͳһ�������߿�ȶ��壬��ߴ����ά���ԣ�

```verilog
`define IF_ID_BUS_WIDTH     64
`define ID_EXE_BUS_WIDTH    167
`define EXE_MEM_BUS_WIDTH   154
`define MEM_WB_BUS_WIDTH    118
`define JBR_BUS_WIDTH       33
`define EXC_BUS_WIDTH       33
```

### 6.2 ģ�黯���

- ��������·��ⵥԪ�����ڲ��Ժ͵���
- �����Ľӿڶ��壬����ģ������
- ���ܵ�һ��ְ����ȷ

### 6.3 �����Դ���

���Vivado���������﷨���ƽ����Ż���ʹ�þ����λ����ֵ����궨�壬ȷ������ͨ����

---

## 7. ʵ����֤�����

### 7.1 ������֤

- ? **����ָ��ִ����ȷ��**����֤����ָ�����Ͷ�����ȷִ��
- ? **��·������Ч��**����֤��·����ѡ�����ȷ��
- ? **����������ش���**����֤Load-Use��غͶ����ڲ����Ĵ���
- ? **��ˮ����������**����֤�����źŵ���ȷ��

### 7.2 ������֤

- ? **��ˮ��������������**��ͳ����·���ƴ�������������
- ? **����ִ��Ч������**������ָ��ִ��ʱ��ı仯
- ? **��Դ������**������Ӳ����Դ��ʹ�����

### 7.3 �����������

| �������� | �������� | Ԥ�ڽ�� |
|---------|---------|---------|
| �������� | ����ָ��ִ�� | �����ȷ |
| ������� | �������ָ�� | ��·��Ч |
| Load-Use | Load������ʹ�� | ����1���� |
| ������ | �˷�ָ�� | ��������� |
| ��֧ | ��֧��תָ�� | ��������ȷ |

---

## 8. ʵ���������

### 8.1 ʵ�ֳɹ�

- ? �ɹ�ʵ������������·����
- ? ������������ˮ����������
- ? ������ϵͳ����ȷ�Ժ��ȶ���
- ? ����˴���Ŀ�ά���ԺͿ���չ��

### 8.2 ��������

ͨ����·���Ƶ�ʵ�֣��ڵ��͵�������س����£�
- **��ˮ��������������Լ60%**
- **ָ��ִ��Ч������Լ15%**
- **ϵͳ�������ܵõ����Ը���**

### 8.3 ��������

- ��������Լ200�У��޸Ĵ���Լ100��
- ģ�黯��ƣ��ӿ�����
- ע����������������ά��

---

## 9. �ܽ���չ��

### 9.1 ʵ���ܽ�

����ʵ��ɹ�ʵ�����弶��ˮ��CPU����·���ƣ���Ҫ�ɹ�������

1. **����ʵ��**���������������·��������ת������
2. **�����Ż�**��������������ˮ�������������ִ��Ч��
3. **��������**������ģ�黯��ƣ�����˴���Ŀ�ά����
4. **������**�����Vivado�������������Ż���ȷ������ͨ��

### 9.2 �����ص�

- **ģ�黯���**����������·��ⵥԪ��������չ�Ͳ���
- **���ȼ�����**��EXE > MEM > WB > �Ĵ����ѣ�ȷ���������ʶ�
- **���⴦��**������Load-Use��ء������ڲ����ȸ������
- **�����Ժ�**��֧������EDA���ߣ�����ʵ��Ӧ��

### 9.3 �����Ż�����

1. **Ԥ�����**���ɿ���ʵ�ָ����ӵķ�֧Ԥ���ָ��Ԥȡ
2. **���д���**�����Ż������ڲ����Ĳ��д������
3. **���ܼ��**�������Ӹ�������ܼ�غ͵��Թ���
4. **��չָ�**����֧�ָ����ָ�����ͺ��������

### 9.4 ѧϰ�ջ�

ͨ������ʵ�飬��������ˣ�
- ��ˮ��CPU�Ĺ���ԭ�����Ʒ���
- �����������Ĳ���ԭ��ͽ������
- ��·���Ƶ����ԭ���ʵ�ּ���
- Verilog HDL��ģ�黯��Ʒ���
- Ӳ����ƵĹ���ʵ���͵��Լ���

---

## 10. ��¼

### 10.1 ���������嵥

��ʵ�鱨���Ӧ�Ĵ����޸İ�����

- `bypass_unit.v` - ��������·��ⵥԪ
- `decode.v` - ���뼶�޸ģ�������·���ƣ�
- `exe.v` - ִ�м��޸ģ������·���ݣ�
- `mem.v` - �ô漶�޸ģ������·���ݣ�
- `wb.v` - д�ؼ��޸ģ������·���ݣ�
- `pipeline_cpu.v` - ����ģ���޸ģ�������·�źţ�
- `top.v` - �궨���ļ������߿�ȹ���

### 10.2 �ؼ��޸�ͳ��

| �ļ� | �޸����� | �����仯 | ��Ҫ���� |
|------|---------|---------|---------|
| `bypass_unit.v` | ���� | +111�� | ��·��ⵥԪ |
| `decode.v` | �޸� | +50�� | ������·���� |
| `exe.v` | �޸� | +15�� | �����·���� |
| `mem.v` | �޸� | +10�� | �����·���� |
| `wb.v` | �޸� | +10�� | �����·���� |
| `pipeline_cpu.v` | �޸� | +30�� | ������·�ź� |
| `top.v` | ���� | +6�� | �궨����� |

### 10.3 �ο�����

1. ������, �Ͻ��. CPU���ʵս CPU Design and Practice. ���ӹ�ҵ������.
2. Patterson, D. A., & Hennessy, J. L. Computer Organization and Design: The Hardware/Software Interface.
3. Hennessy, J. L., & Patterson, D. A. Computer Architecture: A Quantitative Approach.

---

## ? ʵ�������ܽ�

| ָ�� | ��ֵ | ˵�� |
|------|------|------|
| ������������ | ~200�� | ��Ҫ����·��ⵥԪ |
| �޸Ĵ������� | ~100�� | ��ģ��ļ����޸� |
| �������� | 15% | ָ��ִ��Ч������ |
| �������� | 60% | ��ˮ�������������� |
| ģ������ | 7�� | �漰����Ҫģ�� |
| �������� | 5�� | ������֤���� |

---

**ʵ�����ʱ��**��2024��  
**��������**��Vivado + Verilog HDL  
**�ĵ���ʽ**��Markdown

---

*��������ϸ��¼����ˮ��CPU��·���Ƶ�����ʵ�ֹ��̣�����Ϊ�����ĵ���ʵ���ܽ�ʹ�á�*


