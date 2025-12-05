% Author: Abhirath Koushik
%
% Brief: Realistic Attraction/Repulsion Simulation (Bayanga, CAR)
%        - 3 Elephants (Center, Top-Left, Bottom-Right)
%        - Real-world Scale (1px = 20m)
%        - On-Screen Dashboard & Measurements
%        - Added Mic and its range on the Dashboard
%
% --- Reset and Setup ---
clear;
clc;
close all;

% --- Screen Settings ---
WIDTH = 600;  % Represents 12km
HEIGHT = 400; % Represents 8km

% --- REALISTIC SCALE FACTORS ---
METERS_PER_PIXEL = 20; 

% --- Simulation Elements ---

% --- Setup Multiple Elephants ---
num_elephants = 3; 
start_pos = [
    WIDTH/2, HEIGHT/2;      % Elephant 1: Center
    50, 50;                 % Elephant 2: Top-Left
    WIDTH-50, HEIGHT-50     % Elephant 3: Bottom-Right
];

for k = 1:num_elephants
    players(k).x = start_pos(k, 1);
    players(k).y = start_pos(k, 2);
    players(k).radius = 10; 
    players(k).speed = 2.0; 
    players(k).force_strength = 4.0; 
    players(k).attractorEntryTime = 0;
    players(k).attractorTimeout = 10; 
    players(k).state = "SEEKING"; 
end

% --- Zones ---
% Attractor (Green Zone / Dzanga)
attractor.x = WIDTH * 0.25; 
attractor.y = HEIGHT / 2;
attractor.radius = 25; % 500m real radius

% Repulsor (Red Zone / Bayanga Village)
repulsor.x = WIDTH * 0.75;
repulsor.y = HEIGHT / 2;
repulsor.radius = 75; % 1.5km real radius

% --- Infrasound Microphone ---
mic.x = WIDTH * 0.40; 
mic.y = HEIGHT / 2;
mic.range_elephant = 200; % 4km real range
mic.range_poacher = 20;   % 400m real range
mic.detected_elephant = false;
mic.detected_poacher = false;

% --- Poachers ---
% Poacher 1 (Orbiting Red Zone)
poacher1.radius = 8;
poacher1.speed = 0.8;  
poacher1.jitter_strength = 3.0; 
poacher1.tether_strength = 0.5; 
poacher1.orbit_strength = 1.0;   
poacher1.patrol_radius = repulsor.radius + 15; 
poacher1.x = repulsor.x - poacher1.patrol_radius; 
poacher1.y = repulsor.y;                         
poacher1.avoid_radius = 50; 

% Poacher 2 (Orbiting Green Zone)
poacher2.radius = 8;
poacher2.speed = 0.8;
poacher2.jitter_strength = 3.0; 
poacher2.tether_strength = 0.5; 
poacher2.orbit_strength = 2.0;   
poacher2.patrol_radius = attractor.radius + 15; 
poacher2.x = attractor.x + poacher2.patrol_radius; 
poacher2.y = attractor.y;                         
poacher2.avoid_radius = 50; 

% --- Colors ---
GREEN_ZONE = [0 1 0 0.2]; 
RED_ZONE = [1 0 0 0.2];
PLAYER_COLOR = 'b';
POACHER_COLOR = 'm';
MIC_COLOR_IDLE = 'c'; 

% --- Initialize Figure ---
h_fig = figure('Name', 'Realistic Elephant Simulation (Bayanga, CAR)');
set(h_fig, 'MenuBar', 'none', 'ToolBar', 'none');
ax = gca;
hold(ax, 'on');
axis(ax, [0 WIDTH 0 HEIGHT]);
axis(ax, 'equal');
box(ax, 'on');
set(ax, 'XTick', [], 'YTick', []);
set(ax, 'YDir', 'reverse');

try
    img = imread('dzanga_bayanga.png'); 
    image(ax, 'XData', [0 WIDTH], 'YData', [0 HEIGHT], 'CData', img);
catch
    set(ax, 'Color', 'k');
end

% --- STATIC VISUALS (Drawn Once) ---

% 1. Draw Yellow Border representing the Map Boundary
rectangle(ax, 'Position', [1, 1, WIDTH-2, HEIGHT-2], ...
          'EdgeColor', 'y', 'LineWidth', 2);

% 2. Draw "Dashboard" / Measurements Text
info_str = {
    '\bf\color{white}--- SIMULATION METRICS ---';
    sprintf('Map Area: 12 km x 8 km');
    sprintf('Scale: 1 px = %d meters', METERS_PER_PIXEL);
    ' ';
    '\bf\color{green}Green Zone:';
    sprintf('Radius: %.0f m (25px)', attractor.radius * METERS_PER_PIXEL);
    ' ';
    '\bf\color{red}Red Zone (Village):';
    sprintf('Radius: %.0f m (75px)', repulsor.radius * METERS_PER_PIXEL);
    ' ';
    '\bf\color{cyan}Microphone Specs:';
    sprintf('Elephant Range: %.0f km (200px)', (mic.range_elephant * METERS_PER_PIXEL)/1000);
    sprintf('Poacher Range: %.0f m (10px)', mic.range_poacher * METERS_PER_PIXEL);
};

% Place text in Top-Left corner (x=10, y=20)
text(ax, 10, 20, info_str, 'VerticalAlignment', 'top', ...
     'FontSize', 8, 'BackgroundColor', [0 0 0 0.6], 'Margin', 5);


% --- Initialize Dynamic Handles ---
h_attractor = [];
h_repulsor = [];
for k = 1:num_elephants
    h_players(k) = plot(NaN, NaN); 
end
h_poacher1 = []; 
h_poacher2 = []; 
h_mic = []; 
h_mic_range_e = []; 
h_mic_range_p = []; 
h_caught_text = []; 
h_mic_text = [];    

tic; 
while ishandle(h_fig) 
    
    % --- Poacher 1 Logic ---
    dist_p1_to_home = norm([poacher1.x - repulsor.x, poacher1.y - repulsor.y]);
    p1_dx = (rand() - 0.5) * poacher1.jitter_strength;
    p1_dy = (rand() - 0.5) * poacher1.jitter_strength;
    if dist_p1_to_home > 0
        rad_vec_x = (poacher1.x - repulsor.x) / dist_p1_to_home;
        rad_vec_y = (poacher1.y - repulsor.y) / dist_p1_to_home;
        tan_vec_x = -rad_vec_y;
        tan_vec_y = rad_vec_x;
        radius_error = poacher1.patrol_radius - dist_p1_to_home;
        p1_dx = p1_dx + rad_vec_x * radius_error * poacher1.tether_strength;
        p1_dy = p1_dy + rad_vec_y * radius_error * poacher1.tether_strength;
        p1_dx = p1_dx + tan_vec_x * poacher1.orbit_strength;
        p1_dy = p1_dy + tan_vec_y * poacher1.orbit_strength;
    end
    p1_magnitude = norm([p1_dx, p1_dy]);
    if p1_magnitude > 0
        p1_dx = (p1_dx / p1_magnitude) * poacher1.speed;
        p1_dy = (p1_dy / p1_magnitude) * poacher1.speed;
    end
    poacher1.x = poacher1.x + p1_dx;
    poacher1.y = poacher1.y + p1_dy;
    poacher1.x = max(poacher1.radius, min(WIDTH - poacher1.radius, poacher1.x));
    poacher1.y = max(poacher1.radius, min(HEIGHT - poacher1.radius, poacher1.y));

    % --- Poacher 2 Logic ---
    dist_p2_to_home = norm([poacher2.x - attractor.x, poacher2.y - attractor.y]);
    p2_dx = (rand() - 0.5) * poacher2.jitter_strength;
    p2_dy = (rand() - 0.5) * poacher2.jitter_strength;
    if dist_p2_to_home > 0
        rad_vec_x = (poacher2.x - attractor.x) / dist_p2_to_home;
        rad_vec_y = (poacher2.y - attractor.y) / dist_p2_to_home;
        tan_vec_x = -rad_vec_y;
        tan_vec_y = rad_vec_x;
        radius_error = poacher2.patrol_radius - dist_p2_to_home;
        p2_dx = p2_dx + rad_vec_x * radius_error * poacher2.tether_strength;
        p2_dy = p2_dy + rad_vec_y * radius_error * poacher2.tether_strength;
        p2_dx = p2_dx + tan_vec_x * poacher2.orbit_strength;
        p2_dy = p2_dy + tan_vec_y * poacher2.orbit_strength;
    end
    p2_magnitude = norm([p2_dx, p2_dy]);
    if p2_magnitude > 0
        p2_dx = (p2_dx / p2_magnitude) * poacher2.speed;
        p2_dy = (p2_dy / p2_magnitude) * poacher2.speed;
    end
    poacher2.x = poacher2.x + p2_dx;
    poacher2.y = poacher2.y + p2_dy;
    poacher2.x = max(poacher2.radius, min(WIDTH - poacher2.radius, poacher2.x));
    poacher2.y = max(poacher2.radius, min(HEIGHT - poacher2.radius, poacher2.y));
    
    % --- Elephant Logic ---
    currentTime = toc;
    any_elephant_caught = false; 
    mic.detected_elephant = false;
    mic.detected_poacher = false;

    for k = 1:num_elephants
        dx = (rand() - 0.5) * 4; 
        dy = (rand() - 0.5) * 4; 
        
        dist_to_attractor = norm([players(k).x - attractor.x, players(k).y - attractor.y]);
        dist_to_repulsor = norm([players(k).x - repulsor.x, players(k).y - repulsor.y]);
        dist_to_poacher1 = norm([players(k).x - poacher1.x, players(k).y - poacher1.y]); 
        dist_to_poacher2 = norm([players(k).x - poacher2.x, players(k).y - poacher2.y]); 
        
        % Mic vs Elephant
        dist_to_mic = norm([players(k).x - mic.x, players(k).y - mic.y]);
        if dist_to_mic < mic.range_elephant
            mic.detected_elephant = true;
        end
        
        switch players(k).state
            case "SEEKING" 
                if dist_to_attractor < attractor.radius && dist_to_attractor > 0
                    vec_x = (attractor.x - players(k).x) / dist_to_attractor;
                    vec_y = (attractor.y - players(k).y) / dist_to_attractor;
                    dx = dx + vec_x * players(k).force_strength;
                    dy = dy + vec_y * players(k).force_strength;
                    players(k).state = "WAITING";
                    players(k).attractorEntryTime = currentTime;
                end
            case "WAITING" 
                if dist_to_attractor > 0
                    vec_x = (attractor.x - players(k).x) / dist_to_attractor;
                    vec_y = (attractor.y - players(k).y) / dist_to_attractor;
                    dx = dx + vec_x * players(k).force_strength;
                    dy = dy + vec_y * players(k).force_strength;
                end
                timeInZone = currentTime - players(k).attractorEntryTime;
                if timeInZone >= players(k).attractorTimeout
                    players(k).state = "EXITING";
                end
                if dist_to_attractor >= attractor.radius
                    players(k).state = "SEEKING";
                end
            case "EXITING" 
                if dist_to_attractor > 0
                    vec_x = (players(k).x - attractor.x) / dist_to_attractor;
                    vec_y = (players(k).y - attractor.y) / dist_to_attractor;
                    dx = dx + vec_x * players(k).force_strength;
                    dy = dy + vec_y * players(k).force_strength;
                end
                if dist_to_attractor >= (attractor.radius+50)
                    players(k).state = "SEEKING";
                end
        end
        
        % Repulsion (Red Zone)
        if dist_to_repulsor < repulsor.radius && dist_to_repulsor > 0
            vec_x = (players(k).x - repulsor.x) / dist_to_repulsor;
            vec_y = (players(k).y - repulsor.y) / dist_to_repulsor;
            dx = dx + vec_x * players(k).force_strength;
            dy = dy + vec_y * players(k).force_strength;
        end
         
        if dist_to_poacher1 < 30 || dist_to_poacher2 < 30
             any_elephant_caught = true;
        end
        
        magnitude = norm([dx, dy]);
        if magnitude > 0
            dx = (dx / magnitude) * players(k).speed;
            dy = (dy / magnitude) * players(k).speed;
        end
        players(k).x = players(k).x + dx;
        players(k).y = players(k).y + dy;
        
        players(k).x = max(players(k).radius, min(WIDTH - players(k).radius, players(k).x));
        players(k).y = max(players(k).radius, min(HEIGHT - players(k).radius, players(k).y));
    end
    
    % Check Mic vs Poachers
    dist_mic_p1 = norm([poacher1.x - mic.x, poacher1.y - mic.y]);
    dist_mic_p2 = norm([poacher2.x - mic.x, poacher2.y - mic.y]);
    if dist_mic_p1 < mic.range_poacher || dist_mic_p2 < mic.range_poacher
        mic.detected_poacher = true;
    end

    % --- Drawing ---
    if ishandle(h_attractor), delete(h_attractor); end
    if ishandle(h_repulsor), delete(h_repulsor); end
    if ishandle(h_poacher1), delete(h_poacher1); end 
    if ishandle(h_poacher2), delete(h_poacher2); end 
    if ishandle(h_caught_text), delete(h_caught_text); end 
    if ishandle(h_mic), delete(h_mic); end 
    if ishandle(h_mic_range_e), delete(h_mic_range_e); end
    if ishandle(h_mic_range_p), delete(h_mic_range_p); end
    if ishandle(h_mic_text), delete(h_mic_text); end
    for k = 1:num_elephants
        if ishandle(h_players(k)), delete(h_players(k)); end
    end
    
    % Green Zone
    h_attractor = rectangle(ax, 'Position', [attractor.x - attractor.radius, ...
                                          attractor.y - attractor.radius, ...
                                          attractor.radius * 2, ...
                                          attractor.radius * 2], ...
                                'Curvature', [1 1], 'FaceColor', GREEN_ZONE, 'EdgeColor', 'none');
    % Red Zone (Village)
    h_repulsor = rectangle(ax, 'Position', [repulsor.x - repulsor.radius, ...
                                         repulsor.y - repulsor.radius, ...
                                         repulsor.radius * 2, ...
                                         repulsor.radius * 2], ...
                               'Curvature', [1 1], 'FaceColor', RED_ZONE, 'EdgeColor', 'none');
    
    % Draw Mic Ranges
    h_mic_range_e = rectangle(ax, 'Position', [mic.x - mic.range_elephant, ...
                                               mic.y - mic.range_elephant, ...
                                               mic.range_elephant * 2, ...
                                               mic.range_elephant * 2], ...
                              'Curvature', [1 1], 'EdgeColor', [0 1 1 0.2], 'LineStyle', '--');
    
    h_mic_range_p = rectangle(ax, 'Position', [mic.x - mic.range_poacher, ...
                                               mic.y - mic.range_poacher, ...
                                               mic.range_poacher * 2, ...
                                               mic.range_poacher * 2], ...
                              'Curvature', [1 1], 'EdgeColor', [1 0 1 0.5], 'LineStyle', '-');

    % Draw Mic Status
    mic_color = MIC_COLOR_IDLE;
    status_msg = "Mic: Idle";
    if mic.detected_elephant, mic_color = 'b'; status_msg = "Mic: Elephant Detected!"; end
    if mic.detected_poacher, mic_color = 'r'; status_msg = "Mic: Poacher Detected!"; end
    if mic.detected_elephant && mic.detected_poacher, mic_color = [0.5 0 0.5]; status_msg = "Mic: BOTH DETECTED!"; end
    
    h_mic = rectangle(ax, 'Position', [mic.x - 10, mic.y - 10, 20, 20], ...
                      'FaceColor', mic_color, 'EdgeColor', 'w');
    h_mic_text = text(ax, mic.x, mic.y - 20, status_msg, 'Color', 'w', 'HorizontalAlignment', 'center');

    % Draw Poachers
    h_poacher1 = plot(ax, poacher1.x, poacher1.y, 'o', 'MarkerEdgeColor', POACHER_COLOR, ...
                       'MarkerFaceColor', POACHER_COLOR, 'MarkerSize', poacher1.radius * 1.5);
    h_poacher2 = plot(ax, poacher2.x, poacher2.y, 'o', 'MarkerEdgeColor', POACHER_COLOR, ...
                       'MarkerFaceColor', POACHER_COLOR, 'MarkerSize', poacher2.radius * 1.5);
    
    % Draw Elephants
    for k = 1:num_elephants
        h_players(k) = plot(ax, players(k).x, players(k).y, 'o', ...
                           'MarkerEdgeColor', PLAYER_COLOR, ...
                           'MarkerFaceColor', PLAYER_COLOR, ...
                           'MarkerSize', players(k).radius * 1.5);
    end
                       
    if any_elephant_caught
        h_caught_text = text(ax, WIDTH/2, HEIGHT/2, 'CAUGHT!', ...
                             'Color', 'r', 'FontSize', 40, ...
                             'FontWeight', 'bold', ...
                             'HorizontalAlignment', 'center');
    end
    
    drawnow limitrate;
    pause(0.016); 
    
end
disp('Simulation window closed.');
