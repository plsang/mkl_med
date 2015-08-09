
% define a class which holds the parameter myValue
classdef DbHandle < handle
    properties
        database = [];
    end 
    methods 
        function obj = DbHandle() % constructor
        end
    end
end

