function [ EUDs_vector ] = EUDs( patient_table )
%Outputs the uniform doses to each tumour in the patient table
num_tumours = max(patient_table.ID);
EUDs_vector = zeros(num_tumours, 1);

for i = 1 : num_tumours
    EUDs_vector(i) = mean(patient_table.dose(patient_table.ID == i));
end