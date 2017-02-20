%% Projeto de um receptor DTMF
%
% Alunos: André Felippe Weber, Gabriel Cozer Cantu e Maria Luiza Theisges

% Parâmetros iniciais
clear all; close all; clc;

N = 11;
Fs_inicial = 8000;
Fc_inicial = 2000;
Wp = Fc_inicial/Fs_inicial;

% Carregamento do sinal contendo os dígitos
[data_orig, fs_orig] = audioread('DTMF013#.wav');

% Filtragem antes de iniciar o processo de detecção. Retirar possíveis frequências acima de 2kHz
[b,a] = butter(2, Wp);
data_filt = filter(b,a,data_orig);

% Processo de subamostragem
Data = data_filt(1:N:end);
Fs = fs_orig/N;
subplot(311); plot(Data); title('Sinal DTMF');

% Separação das frequências mais baixas (linhas) das mais altas (colunas)
Fc_fpb = 960;
Fc_fpa = 1190;
Wp_fpb = Fc_fpb/(Fs/2);
Wp_fpa = Fc_fpa/(Fs/2);

[b1,a1] = butter(10, Wp_fpb,'low');
Signal_low = filter(b1,a1,Data);
[b2,a2] = butter(10, Wp_fpa,'high');
Signal_high = filter(b2,a2,Data);
subplot(312); plot(Signal_low); ylim([-1 1]); title('Sinal com frequências baixas DTMF'); 
subplot(313);plot(Signal_high); ylim([-1 1]); title('Sinal com frequências altas DTMF');

% Projeto dos filtros FIR Passa-Banda, utilizando a Janela de Hamming
Ws1 = 627.3/(Fs/2); Wp1 = 688.5/(Fs/2); Wp2 = 709.5/(Fs/2); Ws2 = 767/(Fs/2);
filtro1 = fir1(100, [Wp1 Wp2]);

Ws1 = 847/(Fs/2); Wp1 = 929/(Fs/2); Wp2 = 957.15/(Fs/2); Ws2 = 1035.1/(Fs/2);
filtro2 = fir1(100, [Wp1 Wp2]);

Ws1 = 1088.1/(Fs/2); Wp1 = 1193/(Fs/2); Wp2 = 1229.2/(Fs/2); Ws2 = 1330/(Fs/2);
filtro3 = fir1(100, [Wp1 Wp2]);

Ws1 = 1202.4/(Fs/2); Wp1 = 1318/(Fs/2); Wp2 = 1358.1/(Fs/2); Ws2 = 1469.6/(Fs/2);
filtro4 = fir1(100, [Wp1 Wp2]);

Ws1 = 1329.3/(Fs/2); Wp1 = 1457/(Fs/2); Wp2 = 1501.15/(Fs/2); Ws2 = 1625/(Fs/2);
filtro5 = fir1(100, [Wp1 Wp2]);

% Passagem dos sinais pelos filtros FIR (STF)
signal_697 = filter(filtro1, 1, Signal_low);
signal_941 = filter(filtro2, 1, Signal_low);
signal_1209 = filter(filtro3, 1, Signal_high);
signal_1336 = filter(filtro4, 1, Signal_high);
signal_1477 = filter(filtro5, 1, Signal_high);

figure(2)
subplot(511); plot(signal_697); title('Linha 1 - Frequência de 697 Hz');
subplot(512); plot(signal_941); title('Linha 4 - Frequência de 941 Hz');
subplot(513); plot(signal_1209); title('Coluna 1 - Frequência de 1209 Hz');
subplot(514); plot(signal_1336); title('Coluna 2 - Frequência de 1336 Hz');
subplot(515); plot(signal_1477); title('Coluna 3 - Frequência de 1477 Hz');

% Regeneração dos sinais (Retificador R)
signal_697_reg = abs(signal_697);
signal_941_reg = abs(signal_941);
signal_1209_reg = abs(signal_1209);
signal_1336_reg = abs(signal_1336);
signal_1477_reg = abs(signal_1477);

figure(3)
subplot(511); plot(signal_697_reg);  title('Linha 1 - Frequência de 697 Hz - Regeneração do Sinal');
subplot(512); plot(signal_941_reg);  title('Linha 4 - Frequência de 941 Hz - Regeneração do Sinal');
subplot(513); plot(signal_1209_reg); title('Coluna 1 - Frequência de 1209 Hz - Regeneração do Sinal');
subplot(514); plot(signal_1336_reg); title('Coluna 2 - Frequência de 1336 Hz - Regeneração do Sinal');
subplot(515); plot(signal_1477_reg); title('Coluna 3 - Frequência de 1477 Hz - Regeneração do Sinal');

% Projeto do Filtro de Pólo Único
Wp3 = 100/(Fs/2);
[b3, a3] = butter(1, Wp3);

signal_spf1 = filter(b3, a3, signal_697_reg);
signal_spf2 = filter(b3, a3, signal_941_reg);
signal_spf3 = filter(b3, a3, signal_1209_reg);
signal_spf4 = filter(b3, a3, signal_1336_reg);
signal_spf5 = filter(b3, a3, signal_1477_reg);

figure(4)
subplot(511); plot(signal_spf1); title('Linha 1 - Frequência de 697 Hz - Envoltória do Sinal DTMF');
subplot(512); plot(signal_spf2); title('Linha 4 - Frequência de 941 Hz - Envoltória do Sinal DTMF');
subplot(513); plot(signal_spf3); title('Coluna 1 - Frequência de 1209 Hz - Envoltória do Sinal DTMF');
subplot(514); plot(signal_spf4); title('Coluna 2 - Frequência de 1336 Hz - Envoltória do Sinal DTMF');
subplot(515); plot(signal_spf5); title('Coluna 3 - Frequência de 1477 Hz - Envoltória do Sinal DTMF');

% Setor de Decisão
s697 = signal_spf1 > 0.15;
s941 = signal_spf2 > 0.15;
s1209 = signal_spf3 > 0.15;
s1336 = signal_spf4 > 0.15;
s1477 = signal_spf5 > 0.15;


% Verificação das linhas e colunas para detectar qual número foi teclado.
% Se resultado for maior que 1, indica que há um sinal DTMF. Esse valor é
% armazanado no vetor criado (DTMF). E, no fim, os dígitos são impressos na
% tela. A variável index é incrementada para que o próximo dígito seja
% armazenado na próxima posição do vetor. Para esse projeto, o objetivo é
% reconhecer os números 0, 1, 3 e #. Portanto, apenas esses valores
% especificados que serão impressos na tela.

index = 1;

if(sum(and(s697,s1209))>1)
    DTMF(1,index) = 1;
    index = index + 1;
end;

if(sum(and(s697,s1477))>1)
    DTMF(1,index) = 3;
    index = index + 1;
end;

if(sum(and(s941,s1336))>1)
    DTMF(1,index) = 0;
    index = index + 1;
end;

if(sum(and(s941,s1477))>1)
    DTMF(1,index) = '#';
    index = index + 1;
end;

disp('Você digitou os números: '); DTMF

% O matlab imprime o # como sendo o número decimal 35 de acordo com tabela
% ASCII.