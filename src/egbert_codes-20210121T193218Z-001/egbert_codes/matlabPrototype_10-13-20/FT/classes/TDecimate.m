classdef TDecimate
    %  TDdeicmate class -- now just a single class to define full
    %  decimation structure
    properties
        %    this is just copied from the structures used before -- might
        %    modify
        decFactor   % this is an array of size NDec
    end
    properties (Dependent)
        NDec
    end
    
    methods
        function obj = TDecimate()
            %class constructor:  for now just create empty object
        end
        function obj = SetDec(obj,dec)
            %   just sets properties from structure in one cell from old
            %   cfg file
            obj.decFactor = zeros(length(dec),1);
            for idec = 1:obj.NDec
                obj.decFactor(idec) = dec{idec}.decFac;
            end
        end
        %******************************************************************
        function result = get.NDec(obj)
            result = length(obj.decFactor);
        end
    end
end

