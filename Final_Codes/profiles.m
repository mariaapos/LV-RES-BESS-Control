load('Interpolated_1min.mat');

t = 1:1440;

figure;
plot(t, consumption_1min, 'b', 'LineWidth', 1.5);
ylim([0 1]);
xlabel('t (min)');
ylabel('Percentage of Nominal Power Consumed');
xticks(0:200:1440);
grid on;

figure;
plot(t, generation_1min, 'r', 'LineWidth', 1.5);
xlabel('t (min)');
ylabel('Percentage of Nominal Power Produced');
xticks(0:200:1440);
grid on;
