% Takes in a range parameter and returns prime numbers within the range
% Adam Zimmerman, May 2020
clc
clearvars global
% prompt = {'Input number range separated by a space:'};
% dlgtitle = 'Prime Number Range';
% dims = [1 40];
% output = inputdlg(prompt,dlgtitle,dims);
% min = str2double(output{1}{1}); % stuck on how to index first str within cell

min = 1;
max = 10^6;
previousIntegers = 1;
sizePreviousIntegers = size(previousIntegers);
cantBePrime = 0;
couldBePrime = 0;
primes = [];
tic
for currentInteger = min:max
    for previousInteger = 1:previousIntegers
        if mod(currentInteger, previousInteger) ~= 0 ...
                && currentInteger ~= previousInteger && previousInteger ~= 1
            couldBePrime = 1;
        end
        if mod(currentInteger, previousInteger) == 0 ...
                && currentInteger ~= previousInteger && previousInteger ~= 1
            cantBePrime = 1;
        end
    end
    if cantBePrime == 0 && couldBePrime == 1
        primes = [primes, currentInteger];
    end
    cantBePrime = 0;
    couldBePrime = 0;
    previousIntegers = previousIntegers + 1;

end
toc
histogram2(primes,primes, max)