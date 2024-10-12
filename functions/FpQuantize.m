function [fixPtValue,decValue,outErr,satFlag,underFlag,dimOp] = FpQuantize(inOp,wordSize,bp,method)
%FPQUANTIZE Converte valori a doppia precisione in virgola fissa.
%           [FIXPTVALUE, DECVALUE, OUTERR, SATFLAG, UNDERFLAG, DIMOP] = ...
%                          FPQUANTIZE(INOP, WORDSIZE, BP, METHOD) 
%           restituisce cinque array delle stesse dimensioni di inOp + un vettore
%           riga di due elementi:
%
%           FIXPTVALUE contiene i valori quantizzati di inOp.
%           DECVALUE   contiene il decimale equivalente alla stringa binaria senza
%                      virgola.
%           OUTERR     contiene l'errore commesso.
%           SATFLAG    indica che c'è stato overflow --> il risultato viene saturato.
%           UNDERFLAG  indica che c'è stato underflow.
%           DIMOP      restituisce il formato di inOp: wordSize e bp.
%
%           INOP è l'array di valori da quantizzare.
%
%           WORDSIZE	indica il numero di bit con cui si vuole quantizzare INOP.
%           Un WORDSIZE positivo indica operandi UNSIGNED, uno negativo
%           indica operandi SIGNED in complemento a 2.
%           Esso ammette valori in modulo da 2 a 32.
%
%           BP indica quante cifre binarie dopo la virgola si vogliono usare.
%           Valori ammessi variano da 0 a modulo di WORDSIZE.
%				
%				METHOD è una stringa che indica il metodo di quantizzazione: 
%						arrotondamento al più vicino 	'round'
%						arrotondamento per eccesso		'ceil'
%						troncamento verso -inf			'floor'
%						troncamento verso zero			'fix'
%				Per default la funzione esegue un troncamento verso zero 
%																			
% Version 2.0 20-Dic-99
% Copyright (c) 1999 by DIEI - Università di Perugia

% Controllo argomenti
msg = nargchk(3,4,nargin);   
if ~isempty(msg)
   error(msg);
end
if nargin == 3,
   method = 'fix';
end

msg = 'Valori validi per wordSize sono [-32,-2] U [2:32].';
word_size = abs(wordSize);
if (isstr(wordSize) | ~isreal(wordSize) | max(size(wordSize)) ~= 1)|...
      ((word_size < 2) | (word_size > 32)),
  error(msg);
end

msg = 'Valori validi di bp sono 0:abs(wordSize).';
if isstr(bp) | ~isreal(bp) | max(size(bp)) ~= 1,
  error(msg);
end
if (bp ~= round(bp)) | (bp < 0) | (bp > word_size),
  error(msg);
end;

% Inizializzazione array
fixPtValue = zeros(size(inOp));
numStep = zeros(size(inOp));
decValue = zeros(size(inOp));
outErr = zeros(size(inOp));
satFlag = zeros(size(inOp));
underFlag = zeros(size(inOp));

% Calcolo limite inferiore e superiore 
lowlimit = 0.5*(sign(wordSize)-1)*2^(word_size-bp-1);
highlimit = 0.25*(sign(wordSize)+3)*2^(word_size-bp)-2^(-bp);
precision = 2^(-bp);

% Quantizzazione
eval(['numStep = ',method,'(inOp/precision);']);
fixPtValue = numStep*precision;

% Verifica Overflow e Underflow
satFlag(find((fixPtValue > highlimit)|(fixPtValue < lowlimit))) = 1;
underFlag(find(abs(inOp) < precision & inOp ~= 0)) = 1;
dimOp = [wordSize,bp];

% Saturazione
fixPtValue(find(fixPtValue > highlimit)) = highlimit;
fixPtValue(find(fixPtValue < lowlimit)) = lowlimit;
numStep = fixPtValue/precision;
decValue(find(numStep>=0)) = numStep(find(numStep>=0));
decValue(find(numStep<0)) = 2^word_size + numStep(find(numStep<0));

% Calcolo errore
outErr = inOp - fixPtValue;

return


