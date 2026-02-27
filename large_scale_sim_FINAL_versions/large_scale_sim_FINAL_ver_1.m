%
% Author: Abhirath Koushik
%
% Brief: Attraction/Repulsion Simulation of Elephant with Poachers,
%        Elephant (Blue circle), Green Zone (attraction), Red Zone
%        (repulsion), Poachers (Magenta moving circles)  
% 
% Revision 1 (11-15-2025): Initial simulation with 1 elephant, 2 Zones and 2 poachers
% Revision 2 (01-22-2026): Large Scale Simulation, added Mic with detection
% states, 5 red zones, 5 elephants, 2 poachers
% Revision 3 (02-19-2026): Mics surround every red zone, 20 Elephants, 10
% Poachers, Live Report of Poached elephants or Poachers Nuetralized
% Revision 4 (02-26-2026): Multiple mic placement strategies, 
% memory-saving for the mics, ranger deployed to nuetralize poachers
%

clear;
clc;
close all;
% Initialize Random Seed
rng('shuffle');
% -------------------------------------------------------------------------
% 1. CONFIGURATION & SCALING
% -------------------------------------------------------------------------
WIDTH = 600;   
HEIGHT = 600;  
SIDEBAR_W = 240; 
REF_WIDTH = 1000; REF_HEIGHT = 1000;
SF_X = WIDTH / REF_WIDTH;
SF_Y = HEIGHT / REF_HEIGHT;
METERS_PER_PIXEL = 158; 
SPEED_ELEPHANT_MPS = 1.11; % Exactly 4 km/hr
SPEED_POACHER_MPS = 0.55;  % Exactly 2 km/hr
SPEED_RANGER_MPS = 5.55;   % Exactly 20 km/hr
DETECTION_PROBABILITY = 0.90; 
SCAN_INTERVAL = 1.0;   

% --- MIC PLACEMENT STRATEGY SELECTOR ---
% 1 = Uniform Global Spread
% 2 = Targeted Fortress (Red Zones & Green Zone)
% 3 = Perimeter Defense
% 4 = 50/50 Split between Fortress and Perimeter
MIC_STRATEGY = 4; 

% -------------------------------------------------------------------------
% 1.5. SCALING BASED ON REAL-WORLD MEASUREMENTS
% -------------------------------------------------------------------------
m2px = @(meters) meters / METERS_PER_PIXEL;
RAD_NOLA_M = 3040;
RAD_SALO_M = 2280;
RAD_BAYANGA_M = 3040;
RAD_LIDJOMBO_M = 2280;
RAD_MOSSIPA_M = 2280;
BAI_RAD_M = 1900;
BAI_SENSE_M = 6080;
MIC_RANGE_E_M = 3950;
MIC_RANGE_P_M = 2280;
MIC_THREAT_DIST_M = 4560;
POACH_DIST_M = 1520;     
DIST_REACHED_M = 1266;   
AVOID_BUFFER_M = 2533;   
DEEP_FOREST_M = 25333;  

% -------------------------------------------------------------------------
% 2. PARK BOUNDARY DEFINITION 
% -------------------------------------------------------------------------
ref_poly_x = [
    50,   150,  300,  450,  600,  680,  750,  850,  980, ... 
    980,  850,  720,  650,  620,  640,  620,  550,  500, ... 
    450,  380,  350,  350,  320,  250,  200,  100,  50, ...  
    20,   50 
];
ref_poly_y = [
    150,  100,   60,   50,   20,   20,   20,   30,   40, ... 
    120,  140,  140,  300,  400,  500,  650,  800,  900, ... 
    1000, 850,  750,  650,  550,  520,  480,  400,  300, ... 
    280,  150 
];
park_boundary_x = ref_poly_x * SF_X;
park_boundary_y = ref_poly_y * SF_Y;
isInsidePark = @(x, y) inpolygon(x, y, park_boundary_x, park_boundary_y);

% -------------------------------------------------------------------------
% 3. ENVIRONMENT SETUP
% -------------------------------------------------------------------------
% Repulsion Zones (Villages)
repulsors = struct('x', {}, 'y', {}, 'radius', {}, 'name', {});
repulsors(1) = struct('x', 320*SF_X, 'y', 220*SF_Y, 'radius', m2px(RAD_NOLA_M), 'name', 'Nola'); 
repulsors(2) = struct('x', 380*SF_X, 'y', 430*SF_Y, 'radius', m2px(RAD_SALO_M), 'name', 'Salo');
repulsors(3) = struct('x', 480*SF_X, 'y', 600*SF_Y, 'radius', m2px(RAD_BAYANGA_M), 'name', 'Bayanga');
repulsors(4) = struct('x', 380*SF_X, 'y', 750*SF_Y, 'radius', m2px(RAD_LIDJOMBO_M), 'name', 'Lidjombo');
repulsors(5) = struct('x', 190*SF_X, 'y', 120*SF_Y, 'radius', m2px(RAD_MOSSIPA_M), 'name', 'Mossipa');
% Attraction Zone (Bai)
attractor.x = 550 * SF_X; 
attractor.y = 550 * SF_Y;
attractor.radius = m2px(BAI_RAD_M); 
attractor.sensing_range = m2px(BAI_SENSE_M); 

% -------------------------------------------------------------------------
% 4. AGENT INITIALIZATION
% -------------------------------------------------------------------------
% --- ELEPHANTS (20 Total) ---
num_elephants = 20; 
for k = 1:num_elephants
    valid_start = false;
    while ~valid_start
        sx = rand() * WIDTH; sy = rand() * HEIGHT;
        if isInsidePark(sx, sy)
            in_red_zone = false;
            for r = 1:length(repulsors)
                if norm([sx - repulsors(r).x, sy - repulsors(r).y]) < (repulsors(r).radius + m2px(1266))
                    in_red_zone = true; break;
                end
            end
            if ~in_red_zone
                players(k).x = sx; players(k).y = sy;
                valid_start = true;
            end
        end
    end
    
    players(k).radius = 8 * SF_X; 
    players(k).is_poached = false; 
    players(k).poach_time = -999;
    players(k).state = "ROAMING"; 
    players(k).attractorEntryTime = 0;
    players(k).last_visit_time = -999; 
    players(k).vx = 0; players(k).vy = 0; 
    
    valid_target = false;
    while ~valid_target
        tx = rand() * WIDTH; ty = rand() * HEIGHT;
        if isInsidePark(tx, ty)
            in_red_zone = false;
            for r = 1:length(repulsors)
                if norm([tx - repulsors(r).x, ty - repulsors(r).y]) < (repulsors(r).radius + m2px(1266))
                    in_red_zone = true; break;
                end
            end
            if ~in_red_zone
                players(k).target_x = tx; players(k).target_y = ty;
                valid_target = true;
            end
        end
    end
end
% --- POACHERS (10 Total) ---
num_poachers = 10;
for p = 1:num_poachers
    valid_start = false;
    while ~valid_start
        if rand() > 0.5
            start_node = randi(length(repulsors));
            sx = repulsors(start_node).x + (rand()-0.5)*m2px(6000);
            sy = repulsors(start_node).y + (rand()-0.5)*m2px(6000);
            d_green = norm([sx-attractor.x, sy-attractor.y]);
            if isInsidePark(sx, sy) && d_green > attractor.radius + m2px(AVOID_BUFFER_M)
                valid_start = true;
            end
        else
            idx = randi(length(park_boundary_x));
            px = park_boundary_x(idx);
            py = park_boundary_y(idx);
            sx = px + (rand()-0.5)*m2px(5000); 
            sy = py + (rand()-0.5)*m2px(5000);
            if ~isInsidePark(sx, sy)
                valid_start = true;
            end
        end
    end
    
    poachers(p).x = sx; 
    poachers(p).y = sy;
    poachers(p).vx = 0; 
    poachers(p).vy = 0; 
    poachers(p).radius = 8 * SF_X;
    
    valid_target = false;
    while ~valid_target
        tx = rand() * WIDTH; ty = rand() * HEIGHT;
        d_green = norm([tx-attractor.x, ty-attractor.y]);
        if isInsidePark(tx, ty) && d_green > attractor.radius + m2px(AVOID_BUFFER_M)
            poachers(p).target_x = tx; poachers(p).target_y = ty;
            valid_target = true;
        end
    end
    poachers(p).is_caught = false; 
    poachers(p).caught_time = -999;
    
    poachers(p).is_targeted = false;
    poachers(p).ranger_x = -999;
    poachers(p).ranger_y = -999;
    poachers(p).base_x = -999;
    poachers(p).base_y = -999;
end

% -------------------------------------------------------------------------
% 5. SENSOR NETWORK INITIALIZATION
% -------------------------------------------------------------------------
mic_specs.range_e = m2px(MIC_RANGE_E_M);        
mic_specs.range_p = m2px(MIC_RANGE_P_M);        
mic_specs.threat_dist_px = m2px(MIC_THREAT_DIST_M); 
if MIC_STRATEGY == 1
    [mics, num_mics] = place_mics_uniform(WIDTH, HEIGHT, isInsidePark, mic_specs);
elseif MIC_STRATEGY == 2
    [mics, num_mics] = place_mics_fortress(WIDTH, HEIGHT, isInsidePark, mic_specs, repulsors, attractor);
elseif MIC_STRATEGY == 3
    [mics, num_mics] = place_mics_perimeter(WIDTH, HEIGHT, park_boundary_x, park_boundary_y, mic_specs);
elseif MIC_STRATEGY == 4
    [mics, num_mics] = place_mics_optimized_web(WIDTH, HEIGHT, isInsidePark, mic_specs, repulsors, attractor, m2px, park_boundary_x, park_boundary_y);
end
for m = 1:num_mics
    mics(m).elephant_memory = -999999; 
end

% -------------------------------------------------------------------------
% 6. VISUALIZATION & UI
% -------------------------------------------------------------------------
h_fig = figure('Name', 'Dzanga Simulation Dashboard', 'Position', [100, 100, WIDTH + SIDEBAR_W + 50, HEIGHT+120]);
set(h_fig, 'MenuBar', 'none', 'ToolBar', 'none', 'Color', [0.15 0.15 0.15]); 
ax = axes('Units', 'pixels', 'Position', [25, 70, WIDTH, HEIGHT]);
hold(ax, 'on'); axis(ax, [0 WIDTH 0 HEIGHT]); set(ax, 'YDir', 'reverse');
try
    img = imread('dzanga_sangha_updated_black.png'); 
    image(ax, 'XData', [0 WIDTH], 'YData', [0 HEIGHT], 'CData', img);
catch
    set(ax, 'Color', [0.1 0.2 0.1]); 
end
plot(ax, [park_boundary_x, park_boundary_x(1)], [park_boundary_y, park_boundary_y(1)], 'w--', 'LineWidth', 1);

text(ax, 350, 560, 'Dzanga-Sangha National Park', 'Color', 'w', 'FontSize', 10, 'FontWeight', 'bold');
text(ax, 350, 580, 'Area monitored: 4900 sq. Km', 'Color', [0.7 0.85 1], 'FontSize', 10);

% --- UI CONTROLS ---
h_slider = uicontrol('Style', 'slider', 'Min', 1, 'Max', 5000, 'Value', 1000, ...
                     'Position', [WIDTH/2 - 120, 20, 180, 20], 'BackgroundColor', [0.3 0.3 0.3]);
h_slider_label = uicontrol('Style', 'text', 'Position', [WIDTH/2 - 120, 45, 180, 20], ...
                           'String', 'Time Lapse: 1000x', 'FontSize', 10, 'FontWeight', 'bold', ...
                           'BackgroundColor', [0.15 0.15 0.15], 'ForegroundColor', [1 1 1]);
h_play_pause = uicontrol('Style', 'togglebutton', 'Min', 0, 'Max', 1, 'Value', 0, ...
                         'Position', [WIDTH/2 + 80, 20, 80, 25], ...
                         'String', 'PAUSE ||', 'FontSize', 10, 'FontWeight', 'bold', ...
                         'BackgroundColor', [0.8 0.2 0.2], 'ForegroundColor', [1 1 1]);
% --- LIVE REPORT SIDEBAR ---
h_panel = uipanel('Title', ' LIVE MISSION REPORT ', 'FontSize', 11, 'FontWeight', 'bold', ...
                  'Units', 'pixels', 'Position', [WIDTH + 35, 350, SIDEBAR_W - 10, 350], ...
                  'BackgroundColor', [0 0 0], 'ForegroundColor', [1 1 1]);
              
h_report_text = uicontrol('Parent', h_panel, 'Style', 'text', ...
                  'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.9], ...
                  'String', 'Initializing...', 'FontSize', 10, 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0 0 0], 'ForegroundColor', [1 1 1]);
% --- LEGEND PANEL ---
h_leg_panel = uipanel('Title', ' LEGEND ', 'FontSize', 11, 'FontWeight', 'bold', ...
                  'Units', 'pixels', 'Position', [WIDTH + 35, 70, SIDEBAR_W - 10, 270], ...
                  'BackgroundColor', [0 0 0], 'ForegroundColor', [1 1 1]);
              
ax_leg = axes('Parent', h_leg_panel, 'Units', 'normalized', 'Position', [0 0 1 1]);
hold(ax_leg, 'on'); axis(ax_leg, [0 1 0 1]); axis(ax_leg, 'off');
set(ax_leg, 'Color', 'none');
plot(ax_leg, 0.1, 0.90, 'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'w', 'MarkerSize', 8);
text(ax_leg, 0.25, 0.90, 'Safe Elephant', 'Color', 'w', 'FontSize', 9, 'FontWeight', 'bold');
plot(ax_leg, 0.1, 0.80, 'x', 'Color', 'r', 'LineWidth', 2, 'MarkerSize', 10);
text(ax_leg, 0.25, 0.80, 'Poached Elephant', 'Color', 'w', 'FontSize', 9, 'FontWeight', 'bold');
plot(ax_leg, 0.1, 0.70, 'o', 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'w', 'MarkerSize', 6);
text(ax_leg, 0.25, 0.70, 'Active Poacher', 'Color', 'w', 'FontSize', 9, 'FontWeight', 'bold');
plot(ax_leg, 0.1, 0.60, 's', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'w', 'MarkerSize', 6);
text(ax_leg, 0.25, 0.60, 'Active Ranger', 'Color', 'w', 'FontSize', 9, 'FontWeight', 'bold');
plot(ax_leg, 0.1, 0.50, 'p', 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'g', 'MarkerSize', 10);
text(ax_leg, 0.25, 0.50, 'Neutralized Poacher', 'Color', 'w', 'FontSize', 9, 'FontWeight', 'bold');
rectangle(ax_leg, 'Position', [0.07, 0.38, 0.06, 0.04], 'FaceColor', 'b');
text(ax_leg, 0.25, 0.40, 'Mic (Idle)', 'Color', 'w', 'FontSize', 9, 'FontWeight', 'bold');
rectangle(ax_leg, 'Position', [0.07, 0.28, 0.06, 0.04], 'FaceColor', 'w');
text(ax_leg, 0.25, 0.30, 'Mic (Detected)', 'Color', 'w', 'FontSize', 9, 'FontWeight', 'bold');
rectangle(ax_leg, 'Position', [0.07, 0.18, 0.06, 0.04], 'FaceColor', [0.9 0.4 0]);
text(ax_leg, 0.25, 0.20, 'Mic (Memory)', 'Color', 'w', 'FontSize', 9, 'FontWeight', 'bold');
rectangle(ax_leg, 'Position', [0.07, 0.08, 0.06, 0.04], 'FaceColor', [0.8 0 0]);
text(ax_leg, 0.25, 0.10, 'Mic (Missed)', 'Color', 'w', 'FontSize', 9, 'FontWeight', 'bold');
% Draw Zones
for r = 1:length(repulsors)
    rectangle(ax, 'Position', [repulsors(r).x-repulsors(r).radius, repulsors(r).y-repulsors(r).radius, repulsors(r).radius*2, repulsors(r).radius*2], ...
              'Curvature', [1 1], 'FaceColor', [1 0 0 0.3], 'EdgeColor', 'none');
    text(ax, repulsors(r).x, repulsors(r).y, repulsors(r).name, ...
        'Color', 'w', 'FontSize', 9, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
rectangle(ax, 'Position', [attractor.x-attractor.radius, attractor.y-attractor.radius, attractor.radius*2, attractor.radius*2], ...
          'Curvature', [1 1], 'FaceColor', [0 1 0 0.3], 'EdgeColor', 'g', 'LineWidth', 2);
% Target the main axes 'ax'
for k=1:num_elephants, h_players(k)=plot(ax, NaN, NaN); end
for p=1:num_poachers, h_poachers(p)=plot(ax, NaN, NaN); end
for p=1:num_poachers, h_rangers(p)=plot(ax, NaN, NaN); end
for m=1:num_mics
    h_mics(m) = rectangle(ax, 'Position', [0 0 1 1], 'FaceColor', 'b', 'EdgeColor', 'w');
    h_rings_e(m) = rectangle(ax, 'Position', [0 0 1 1], 'Curvature', [1 1], 'EdgeColor', [0 1 1 0.4], 'LineStyle', '--', 'LineWidth', 1.2);
    h_rings_p(m) = rectangle(ax, 'Position', [0 0 1 1], 'Curvature', [1 1], 'EdgeColor', [1 0.8 0 0.5], 'LineStyle', '-', 'LineWidth', 1.2);
end
h_threat_lines = plot(ax, NaN, NaN, 'r-.', 'LineWidth', 2); 
h_status_text = text(ax, WIDTH/2, 50, '', 'FontSize', 20, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'BackgroundColor', [0 0 0 0.6], 'Color', [1 1 1]);

% -------------------------------------------------------------------------
% 6.5. INITIAL RENDER & 10-SECOND COUNTDOWN
% -------------------------------------------------------------------------
for p=1:num_poachers
    set(h_poachers(p), 'XData', poachers(p).x, 'YData', poachers(p).y, 'Marker', 'o', 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'w', 'MarkerSize', 6);
end
for k=1:num_elephants
    set(h_players(k), 'XData', players(k).x, 'YData', players(k).y, 'Marker', 'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'w', 'MarkerSize', max(3, 8*SF_X));
end
for m=1:num_mics
    set(h_mics(m), 'Position', [mics(m).x-3, mics(m).y-3, 6, 6], 'FaceColor', 'b');
    set(h_rings_e(m), 'Position', [mics(m).x-mic_specs.range_e, mics(m).y-mic_specs.range_e, mic_specs.range_e*2, mic_specs.range_e*2]);
    set(h_rings_p(m), 'Position', [mics(m).x-mic_specs.range_p, mics(m).y-mic_specs.range_p, mic_specs.range_p*2, mic_specs.range_p*2]);
end
strat_name = ["Uniform Spread", "Targeted Fortress", "Perimeter Defense", "Combination Fortress & Perimeter"];
init_sidebar_text = sprintf([ ...
    'STRATEGY: %s\n', ...
    '--------------\n', ...
    'TIME ELAPSED\n', ...
    '--------------\n', ...
    '0 Days, 00 Hrs\n\n', ...
    'ELEPHANTS\n', ...
    '--------------\n', ...
    'Total: %d\n', ...
    'Safe/Active: %d\n', ...
    'Poached: 0\n\n', ...
    'POACHERS\n', ...
    '--------------\n', ...
    'Total: %d\n', ...
    'Active: %d\n', ...
    'Neutralized: 0'], ...
    strat_name(MIC_STRATEGY), num_elephants, num_elephants, num_poachers, num_poachers);
set(h_report_text, 'String', init_sidebar_text);
for cd = 10:-1:1
    if ~ishandle(h_fig), break; end
    set(h_status_text, 'String', sprintf('STARTING IN %d...', cd), 'Color', [1 1 0]);
    drawnow;
    pause(1);
end
if ishandle(h_fig)
    set(h_status_text, 'String', '');
end

% -------------------------------------------------------------------------
% 7. MAIN LOOP
% -------------------------------------------------------------------------
tic; last_time = toc; current_sim_time = 0; 
while ishandle(h_fig)
    real_dt = toc - last_time; 
    last_time = toc;
    
    if get(h_play_pause, 'Value') == 1
        set(h_play_pause, 'String', 'PLAY ►', 'BackgroundColor', [0.2 0.8 0.2]);
        drawnow limitrate; 
        continue; 
    else
        set(h_play_pause, 'String', 'PAUSE ||', 'BackgroundColor', [0.8 0.2 0.2]);
    end
    
    time_multiplier = get(h_slider, 'Value');
    current_sim_time = current_sim_time + (real_dt * time_multiplier); 
    set(h_slider_label, 'String', sprintf('Time Lapse: %.0fx', time_multiplier));
    
    step_e = (SPEED_ELEPHANT_MPS * time_multiplier * real_dt) / METERS_PER_PIXEL;
    step_p = (SPEED_POACHER_MPS * time_multiplier * real_dt) / METERS_PER_PIXEL;
    step_r = (SPEED_RANGER_MPS * time_multiplier * real_dt) / METERS_PER_PIXEL;
    
    % --- 1. POACHER MOVEMENT ---
    for p = 1:num_poachers
        if poachers(p).is_caught, continue; end 
        dist = norm([poachers(p).target_x - poachers(p).x, poachers(p).target_y - poachers(p).y]);
        
        if dist < m2px(DIST_REACHED_M)
            valid = false;
            while ~valid
                tx = rand() * WIDTH; ty = rand() * HEIGHT;
                d_green_t = norm([tx - attractor.x, ty - attractor.y]);
                if isInsidePark(tx, ty) && d_green_t > attractor.radius + m2px(AVOID_BUFFER_M)
                    poachers(p).target_x = tx; poachers(p).target_y = ty; valid = true; 
                end
            end
            dist = norm([poachers(p).target_x - poachers(p).x, poachers(p).target_y - poachers(p).y]);
        end
        
        des_vx = (poachers(p).target_x - poachers(p).x) / dist;
        des_vy = (poachers(p).target_y - poachers(p).y) / dist;
        
        d_green = norm([poachers(p).x - attractor.x, poachers(p).y - attractor.y]);
        if d_green < attractor.radius + m2px(3000)
            des_vx = des_vx + ((poachers(p).x - attractor.x)/d_green) * 4.0;
            des_vy = des_vy + ((poachers(p).y - attractor.y)/d_green) * 4.0;
        end
        
        mag_des = norm([des_vx, des_vy]); 
        if mag_des > 0, des_vx = des_vx/mag_des; des_vy = des_vy/mag_des; end
        poachers(p).vx = (poachers(p).vx * 0.95) + (des_vx * 0.05); 
        poachers(p).vy = (poachers(p).vy * 0.95) + (des_vy * 0.05);
        mag_curr = norm([poachers(p).vx, poachers(p).vy]);
        if mag_curr > 0, poachers(p).vx = (poachers(p).vx / mag_curr); poachers(p).vy = (poachers(p).vy / mag_curr); end
        
        was_inside = isInsidePark(poachers(p).x, poachers(p).y);
        nx = poachers(p).x + poachers(p).vx * step_p; 
        ny = poachers(p).y + poachers(p).vy * step_p;
        is_inside_now = isInsidePark(nx, ny);
        
        if was_inside && ~is_inside_now
            poachers(p).vx = -poachers(p).vx; 
            poachers(p).vy = -poachers(p).vy; 
            valid_bounce = false;
            while ~valid_bounce
                tx = rand() * WIDTH; ty = rand() * HEIGHT;
                d_green_t = norm([tx - attractor.x, ty - attractor.y]);
                if isInsidePark(tx, ty) && d_green_t > attractor.radius + m2px(AVOID_BUFFER_M)
                    poachers(p).target_x = tx; poachers(p).target_y = ty; valid_bounce = true; 
                end
            end
        else
            poachers(p).x = nx; 
            poachers(p).y = ny;
        end
    end
    
    % --- 2. ELEPHANT MOVEMENT ---
    for k=1:num_elephants
        if players(k).is_poached, continue; end 
        dist = norm([players(k).target_x - players(k).x, players(k).target_y - players(k).y]);
        d_bai = norm([players(k).x - attractor.x, players(k).y - attractor.y]);
        
        if players(k).state == "ROAMING"
            if (current_sim_time - players(k).last_visit_time) > 60
                if d_bai < attractor.sensing_range, players(k).state = "SEEKING"; end
            end
        elseif players(k).state == "SEEKING"
            if d_bai < attractor.radius
                players(k).state = "WAITING"; players(k).attractorEntryTime = current_sim_time;
            end
        elseif players(k).state == "WAITING"
            if (current_sim_time - players(k).attractorEntryTime) > 10
                players(k).state = "ROAMING"; players(k).last_visit_time = current_sim_time; 
                valid_exit = false;
                while ~valid_exit
                    tx = rand() * WIDTH; ty = rand() * HEIGHT;
                    if isInsidePark(tx, ty) && norm([tx-attractor.x, ty-attractor.y]) > m2px(DEEP_FOREST_M)
                        players(k).target_x = tx; players(k).target_y = ty; valid_exit = true;
                    end
                end
            end
        end
        
        if dist < m2px(AVOID_BUFFER_M) && players(k).state ~= "WAITING"
            valid = false;
            while ~valid
                tx = rand() * WIDTH; ty = rand() * HEIGHT;
                if isInsidePark(tx, ty)
                    in_red_zone = false;
                    for r=1:length(repulsors)
                        if norm([tx - repulsors(r).x, ty - repulsors(r).y]) < (repulsors(r).radius + m2px(1266))
                            in_red_zone = true; break;
                        end
                    end
                    if ~in_red_zone
                        players(k).target_x = tx; players(k).target_y = ty; valid = true; 
                    end
                end
            end
            dist = norm([players(k).target_x - players(k).x, players(k).target_y - players(k).y]);
        end
        
        if players(k).state == "WAITING", des_vx = 0; des_vy = 0; 
        else, des_vx = (players(k).target_x - players(k).x) / dist; des_vy = (players(k).target_y - players(k).y) / dist; end
        
        if players(k).state == "SEEKING"
             des_vx = des_vx + ((attractor.x-players(k).x)/d_bai)*0.8; des_vy = des_vy + ((attractor.y-players(k).y)/d_bai)*0.8;
        end
        
        for r=1:length(repulsors)
            d_rep = norm([players(k).x-repulsors(r).x, players(k).y-repulsors(r).y]);
            if d_rep < repulsors(r).radius + m2px(AVOID_BUFFER_M)
                 des_vx = des_vx + ((players(k).x-repulsors(r).x)/d_rep)*4.0; des_vy = des_vy + ((players(k).y-repulsors(r).y)/d_rep)*4.0;
            end
        end
        
        mag_des = norm([des_vx, des_vy]); if mag_des > 0, des_vx = des_vx/mag_des; des_vy = des_vy/mag_des; end
        players(k).vx = (players(k).vx * 0.95) + (des_vx * 0.05); players(k).vy = (players(k).vy * 0.95) + (des_vy * 0.05);
        mag_curr = norm([players(k).vx, players(k).vy]);
        if mag_curr > 0, players(k).vx = (players(k).vx / mag_curr); players(k).vy = (players(k).vy / mag_curr); end
        
        nx = players(k).x + players(k).vx * step_e; ny = players(k).y + players(k).vy * step_e;
        
        if isInsidePark(nx, ny)
            players(k).x = nx; players(k).y = ny;
        else
            players(k).vx = -players(k).vx; players(k).vy = -players(k).vy; 
            valid_bounce = false;
            while ~valid_bounce
                tx = rand() * WIDTH; ty = rand() * HEIGHT;
                if isInsidePark(tx, ty)
                    in_red_zone = false;
                    for r=1:length(repulsors)
                        if norm([tx - repulsors(r).x, ty - repulsors(r).y]) < (repulsors(r).radius + m2px(1266))
                            in_red_zone = true; break;
                        end
                    end
                    if ~in_red_zone
                        players(k).target_x = tx; players(k).target_y = ty; valid_bounce = true; 
                    end
                end
            end
        end
    end
    
    % --- 3. SENSOR NETWORK & HYSTERESIS LOGIC ---
    for m = 1:num_mics
        if (current_sim_time - mics(m).last_scan) >= SCAN_INTERVAL
            mics(m).last_scan = current_sim_time;
            
            mics(m).active_e = false; mics(m).active_p = false; mics(m).threat = false;
            mics(m).status_text = '';
            
            e_in_range = false; p_in_range = false;
            
            for k=1:num_elephants
                if players(k).is_poached, continue; end
                if norm([players(k).x-mics(m).x, players(k).y-mics(m).y]) < mic_specs.range_e
                    e_in_range = true;
                    if rand() <= DETECTION_PROBABILITY
                        mics(m).active_e = true; 
                        mics(m).elephant_memory = current_sim_time; 
                    end
                end
            end
            
            for p=1:num_poachers
                if poachers(p).is_caught, continue; end
                if norm([poachers(p).x-mics(m).x, poachers(p).y-mics(m).y]) < mic_specs.range_p
                    p_in_range = true;
                    if rand() <= DETECTION_PROBABILITY, mics(m).active_p = true; end
                end
            end
            
            if e_in_range || p_in_range
                if (e_in_range && ~mics(m).active_e) || (p_in_range && ~mics(m).active_p)
                    mics(m).status_text = 'MISSED!';
                end
            end
            
            has_memory = (current_sim_time - mics(m).elephant_memory) <= 14400;
            
            if mics(m).active_p && (mics(m).active_e || has_memory)
                for p=1:num_poachers
                    if poachers(p).is_caught || poachers(p).is_targeted, continue; end
                    
                    if norm([poachers(p).x-mics(m).x, poachers(p).y-mics(m).y]) < mic_specs.range_p
                        mics(m).threat = true;
                        poachers(p).is_targeted = true; 
                        
                        closest_dist = inf; closest_base = 1;
                        for r=1:length(repulsors)
                            d = norm([poachers(p).x-repulsors(r).x, poachers(p).y-repulsors(r).y]);
                            if d < closest_dist, closest_dist = d; closest_base = r; end
                        end
                        
                        poachers(p).base_x = repulsors(closest_base).x;
                        poachers(p).base_y = repulsors(closest_base).y;
                        poachers(p).ranger_x = poachers(p).base_x;
                        poachers(p).ranger_y = poachers(p).base_y;
                    end
                end
            end
        end
    end
    
    % --- 3.5 RANGER INTERCEPTION LOGIC ---
    threat_lines_x = []; threat_lines_y = [];
    alert_intercepted = false;
    
    for p = 1:num_poachers
        if poachers(p).is_targeted && ~poachers(p).is_caught
            dist = norm([poachers(p).x - poachers(p).ranger_x, poachers(p).y - poachers(p).ranger_y]);
            
            threat_lines_x = [threat_lines_x, poachers(p).base_x, poachers(p).ranger_x, poachers(p).x, NaN]; 
            threat_lines_y = [threat_lines_y, poachers(p).base_y, poachers(p).ranger_y, poachers(p).y, NaN];
            
            if dist < m2px(500) 
                poachers(p).is_caught = true;
                poachers(p).caught_time = current_sim_time;
                alert_intercepted = true;
            else
                vec_x = (poachers(p).x - poachers(p).ranger_x) / dist;
                vec_y = (poachers(p).y - poachers(p).ranger_y) / dist;
                poachers(p).ranger_x = poachers(p).ranger_x + (vec_x * step_r);
                poachers(p).ranger_y = poachers(p).ranger_y + (vec_y * step_r);
            end
        end
    end
    
    % --- 4. POACHING CHECK ---
    show_poached_alert = false;
    show_caught_alert = false;
    for k = 1:num_elephants
        if players(k).is_poached 
            if (current_sim_time - players(k).poach_time) < 3.0, show_poached_alert = true; end
            continue; 
        end
        for p = 1:num_poachers
            if poachers(p).is_caught 
                if (current_sim_time - poachers(p).caught_time) < 3.0, show_caught_alert = true; end
                continue; 
            end
            
            if norm([players(k).x-poachers(p).x, players(k).y-poachers(p).y]) < m2px(POACH_DIST_M)
                d_safe = norm([players(k).x - attractor.x, players(k).y - attractor.y]);
                if d_safe > attractor.radius 
                    players(k).is_poached = true; players(k).poach_time = current_sim_time; show_poached_alert = true;
                end
            end
        end
    end
    
    % --- 5. RENDER & UI UPDATE ---
    for p=1:num_poachers
        if poachers(p).is_caught
            set(h_poachers(p), 'XData', poachers(p).x, 'YData', poachers(p).y, 'Marker', 'p', 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'g', 'MarkerSize', 14);
            set(h_rangers(p), 'XData', NaN, 'YData', NaN); 
        else
            set(h_poachers(p), 'XData', poachers(p).x, 'YData', poachers(p).y, 'Marker', 'o', 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'w', 'MarkerSize', 6);
            if poachers(p).is_targeted
                set(h_rangers(p), 'XData', poachers(p).ranger_x, 'YData', poachers(p).ranger_y, 'Marker', 's', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'w', 'MarkerSize', 6);
            else
                set(h_rangers(p), 'XData', NaN, 'YData', NaN);
            end
        end
    end
    
    for k=1:num_elephants
        if players(k).is_poached
             set(h_players(k), 'XData', players(k).x, 'YData', players(k).y, 'Marker', 'x', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'MarkerSize', 12, 'LineWidth', 2);
        else
             set(h_players(k), 'XData', players(k).x, 'YData', players(k).y, 'Marker', 'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'w', 'MarkerSize', max(3, 8*SF_X));
        end
    end
    
    for m=1:num_mics
        color = 'b'; 
        has_memory = (current_sim_time - mics(m).elephant_memory) <= 14400; 
        
        if has_memory
            color = [0.9 0.4 0]; 
        elseif mics(m).active_p || mics(m).active_e
            color = 'w';
        end
        
        if strcmp(mics(m).status_text, 'MISSED!')
            color = [0.8 0 0];
        end
        
        set(h_mics(m), 'Position', [mics(m).x-3, mics(m).y-3, 6, 6], 'FaceColor', color);
        set(h_rings_e(m), 'Position', [mics(m).x-mic_specs.range_e, mics(m).y-mic_specs.range_e, mic_specs.range_e*2, mic_specs.range_e*2]);
        set(h_rings_p(m), 'Position', [mics(m).x-mic_specs.range_p, mics(m).y-mic_specs.range_p, mic_specs.range_p*2, mic_specs.range_p*2]);
    end
    
    set(h_threat_lines, 'XData', threat_lines_x, 'YData', threat_lines_y);
    
    if show_poached_alert
        set(h_status_text, 'String', 'POACHED!', 'Color', [1 0.2 0.2]);
    elseif show_caught_alert
        set(h_status_text, 'String', 'THREAT NEUTRALIZED!', 'Color', [0.2 1 0.2]);
    else
        set(h_status_text, 'String', '');
    end
    
    poached_count = sum([players.is_poached]);
    safe_e = num_elephants - poached_count;
    caught_count = sum([poachers.is_caught]);
    active_p = num_poachers - caught_count;
    
    sim_days = floor(current_sim_time / 86400);
    sim_hours = floor(mod(current_sim_time, 86400) / 3600);
    
    sidebar_text = sprintf([ ...
        'STRATEGY: %s\n', ...
        '--------------\n', ...
        'TIME ELAPSED\n', ...
        '--------------\n', ...
        '%d Days, %02d Hrs\n\n', ...
        'ELEPHANTS\n', ...
        '--------------\n', ...
        'Total: %d\n', ...
        'Safe/Active: %d\n', ...
        'Poached: %d\n\n', ...
        'POACHERS\n', ...
        '--------------\n', ...
        'Total: %d\n', ...
        'Active: %d\n', ...
        'Neutralized: %d'], ...
        strat_name(MIC_STRATEGY), sim_days, sim_hours, num_elephants, safe_e, poached_count, num_poachers, active_p, caught_count);
    
    set(h_report_text, 'String', sidebar_text);
    
    drawnow limitrate;
end

% =========================================================================
% PLACEMENT FUNCTIONS
% =========================================================================
% STRATEGY 1: UNIFORM GLOBAL SPREAD
function [mics, num_mics] = place_mics_uniform(WIDTH, HEIGHT, isInsidePark, mic_specs)
    num_mics = 50;
    mics = repmat(struct('x',0,'y',0,'active_e',false,'active_p',false,'threat',false,'last_scan',0,'status_text',''), num_mics, 1);
    count = 0;
    min_spacing = mic_specs.range_p * 2.5; 
    attempts = 0;
    
    while count < num_mics && attempts < 20000
        mx = rand() * WIDTH; my = rand() * HEIGHT;
        if isInsidePark(mx, my)
            too_close = false;
            for j = 1:count
                if norm([mx - mics(j).x, my - mics(j).y]) < min_spacing
                    too_close = true; break; 
                end
            end
            if ~too_close
                count = count + 1; 
                mics(count).x = mx; mics(count).y = my; 
            end
        end
        attempts = attempts + 1;
        if mod(attempts, 500) == 0, min_spacing = min_spacing * 0.95; end
    end
    mics = mics(1:count);
    num_mics = count;
end
% STRATEGY 2: TARGETED FORTRESS
function [mics, num_mics] = place_mics_fortress(WIDTH, HEIGHT, isInsidePark, mic_specs, repulsors, attractor)
    num_mics = 50;
    mics = repmat(struct('x',0,'y',0,'active_e',false,'active_p',false,'threat',false,'last_scan',0,'status_text',''), num_mics, 1);
    count = 0;
    
    for r = 1:length(repulsors)
        ring_radius = repulsors(r).radius + (mic_specs.range_p * 0.4); 
        circumference = 2 * pi * ring_radius;
        mics_needed = ceil(circumference / (mic_specs.range_p * 1.5));
        
        for i = 1:mics_needed
            angle = (i / mics_needed) * 2 * pi;
            mx = repulsors(r).x + ring_radius * cos(angle);
            my = repulsors(r).y + ring_radius * sin(angle);
            if isInsidePark(mx, my) && count < num_mics
                count = count + 1; mics(count).x = mx; mics(count).y = my; 
            end
        end
    end
    
    if count < num_mics
        ring_radius_g = attractor.radius + (mic_specs.range_p * 0.8);
        circumference_g = 2 * pi * ring_radius_g;
        mics_needed_g = ceil(circumference_g / (mic_specs.range_p * 1.5));
        for i = 1:mics_needed_g
            angle = (i / mics_needed_g) * 2 * pi;
            mx = attractor.x + ring_radius_g * cos(angle);
            my = attractor.y + ring_radius_g * sin(angle);
            if isInsidePark(mx, my) && count < num_mics
                count = count + 1; mics(count).x = mx; mics(count).y = my; 
            end
        end
    end
    
    min_spacing = mic_specs.range_p * 2.0; 
    attempts = 0;
    while count < num_mics && attempts < 10000
        mx = rand() * WIDTH; my = rand() * HEIGHT;
        if isInsidePark(mx, my)
            too_close = false;
            for j = 1:count
                if norm([mx - mics(j).x, my - mics(j).y]) < min_spacing, too_close = true; break; end
            end
            if ~too_close, count = count + 1; mics(count).x = mx; mics(count).y = my; end
        end
        attempts = attempts + 1;
        if mod(attempts, 500) == 0, min_spacing = min_spacing * 0.9; end
    end
    mics = mics(1:count);
    num_mics = count;
end
% STRATEGY 3: PERIMETER DEFENSE
function [mics, num_mics] = place_mics_perimeter(~, ~, park_boundary_x, park_boundary_y, mic_specs)
    num_mics = 50;
    mics = repmat(struct('x',0,'y',0,'active_e',false,'active_p',false,'threat',false,'last_scan',0,'status_text',''), num_mics, 1);
    count = 0;
    
    total_length = 0;
    for i = 1:length(park_boundary_x)-1
        total_length = total_length + norm([park_boundary_x(i+1)-park_boundary_x(i), park_boundary_y(i+1)-park_boundary_y(i)]);
    end
    
    spacing = total_length / num_mics;
    curr_dist = 0;
    segment = 1;
    
    while count < num_mics && segment < length(park_boundary_x)
        p1 = [park_boundary_x(segment), park_boundary_y(segment)];
        p2 = [park_boundary_x(segment+1), park_boundary_y(segment+1)];
        seg_len = norm(p2 - p1);
        
        while curr_dist + spacing <= seg_len && count < num_mics
            curr_dist = curr_dist + spacing;
            ratio = curr_dist / seg_len;
            mx = p1(1) + ratio * (p2(1) - p1(1));
            my = p1(2) + ratio * (p2(2) - p1(2));
            
            dir = (p2 - p1) / seg_len;
            normal = [-dir(2), dir(1)]; 
            
            mx = mx + normal(1) * (mic_specs.range_p * 0.5);
            my = my + normal(2) * (mic_specs.range_p * 0.5);
            
            count = count + 1;
            mics(count).x = mx;
            mics(count).y = my;
        end
        curr_dist = curr_dist - seg_len;
        segment = segment + 1;
    end
    mics = mics(1:count);
    num_mics = count;
end
% STRATEGY 4: 50/50 Split between Red Zone Fortress and Perimeter Coverage
function [mics, num_mics] = place_mics_optimized_web(WIDTH, HEIGHT, isInsidePark, mic_specs, repulsors, ~, m2px, park_boundary_x, park_boundary_y)
    num_mics = 50;
    mics = repmat(struct('x',0,'y',0,'active_e',false,'active_p',false,'threat',false,'last_scan',0,'status_text',''), num_mics, 1);
    count = 0;
    
    univ_min_spacing = mic_specs.range_p * 1.2; 
    
    % Phase 1: 50% covering Red Zones
    mics_per_zone = 5;
    for r = 1:length(repulsors)
        ring_radius = repulsors(r).radius + m2px(2533); 
        for i = 1:mics_per_zone
            angle = (i / mics_per_zone) * 2 * pi;
            mx = repulsors(r).x + ring_radius * cos(angle);
            my = repulsors(r).y + ring_radius * sin(angle);
            
            if ~isInsidePark(mx, my)
                mx = repulsors(r).x + (ring_radius * 0.5) * cos(angle);
                my = repulsors(r).y + (ring_radius * 0.5) * sin(angle);
            end
            
            attempts = 0;
            current_radius = ring_radius;
            while attempts < 50
                too_close = false;
                for j = 1:count
                    if norm([mx - mics(j).x, my - mics(j).y]) < univ_min_spacing
                        too_close = true; break; 
                    end
                end
                if ~too_close
                    break; 
                end
                angle = angle + 0.2;
                current_radius = current_radius * 0.95;
                mx = repulsors(r).x + current_radius * cos(angle);
                my = repulsors(r).y + current_radius * sin(angle);
                attempts = attempts + 1;
            end
            
            if count < 25
                count = count + 1; 
                mics(count).x = mx; 
                mics(count).y = my; 
            end
        end
    end
    
    % Phase 2: 50% Perimeter Defense
    total_length = 0;
    for i = 1:length(park_boundary_x)-1
        total_length = total_length + norm([park_boundary_x(i+1)-park_boundary_x(i), park_boundary_y(i+1)-park_boundary_y(i)]);
    end
    
    num_candidates = 300;
    cand_spacing = total_length / num_candidates;
    candidates = zeros(num_candidates, 2);
    c_idx = 1;
    curr_dist = 0;
    segment = 1;
    
    while segment < length(park_boundary_x) && c_idx <= num_candidates
        p1 = [park_boundary_x(segment), park_boundary_y(segment)];
        p2 = [park_boundary_x(segment+1), park_boundary_y(segment+1)];
        seg_len = norm(p2 - p1);
        
        while curr_dist + cand_spacing <= seg_len && c_idx <= num_candidates
            curr_dist = curr_dist + cand_spacing;
            ratio = curr_dist / seg_len;
            mx = p1(1) + ratio * (p2(1) - p1(1));
            my = p1(2) + ratio * (p2(2) - p1(2));
            
            dir = (p2 - p1) / seg_len;
            normal = [-dir(2), dir(1)]; 
            mx = mx + normal(1) * (mic_specs.range_p * 0.5);
            my = my + normal(2) * (mic_specs.range_p * 0.5);
            
            candidates(c_idx, :) = [mx, my];
            c_idx = c_idx + 1;
        end
        curr_dist = curr_dist - seg_len;
        segment = segment + 1;
    end
    
    mics_for_perimeter = num_mics - count;
    target_indices = round(linspace(1, c_idx-1, mics_for_perimeter));
    univ_min_spacing = mic_specs.range_p * 1.5; 
    
    for i = 1:length(target_indices)
        if target_indices(i) == 0, continue; end
        mx = candidates(target_indices(i), 1);
        my = candidates(target_indices(i), 2);
        
        too_close = false;
        for j = 1:count
            if norm([mx - mics(j).x, my - mics(j).y]) < univ_min_spacing
                too_close = true; break;
            end
        end
        
        if ~too_close && isInsidePark(mx, my) && count < num_mics
            count = count + 1;
            mics(count).x = mx;
            mics(count).y = my;
        end
    end
    
    % Phase 3: Adaptive Fill for any missed spots
    min_spacing = mic_specs.range_p * 1.5; 
    attempts = 0;
    while count < num_mics && attempts < 5000
        mx = rand() * WIDTH; my = rand() * HEIGHT;
        if isInsidePark(mx, my)
            too_close = false;
            for j = 1:count
                if norm([mx - mics(j).x, my - mics(j).y]) < min_spacing, too_close = true; break; end
            end
            if ~too_close
                count = count + 1; mics(count).x = mx; mics(count).y = my; 
            end
        end
        attempts = attempts + 1;
        if mod(attempts, 200) == 0, min_spacing = min_spacing * 0.9; end
    end
    
    mics = mics(1:count);
    num_mics = count;
end
