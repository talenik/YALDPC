function w = bitWidth( type )
%bitWidth - return the number of bits for an integer type
%
%	w = bitWidth( type )
%		type is a string, supported types:
%			'uint8', 'uint16', 'uint32', 'uint64'

	switch type		%set bits per word
		case 'uint64' 
			w = 64 ;
		case 'uint32'
			w = 32 ;
		case 'uint16'
			w = 16 ;
		case 'uint8'
			w = 8 ;
		case 'double'
			w = 64 ;
	otherwise
			error('Unsupported type.') ;
	end
end
