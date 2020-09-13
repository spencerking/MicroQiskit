class QuantumCircuit

  attr_accessor :num_qubits
  attr_accessor :num_clbits
  attr_accessor :data

  def initialize(n, m)
    @num_qubits = n
    @num_clbits = m
    @data = Array.new
  end

  def x(q)
    @data.push(['x', q])
  end

  def rx(theta, q)
    @data.push(['rx', theta, q])
  end

  def h(q)
    @data.push(['h', q])
  end

  def cx(s, t)
    @data.push(['cx', s, t])
  end

  def rz(theta, q)
    h(q)
    rx(theta, q)
    h(q)
  end

  def ry(theta, q)
    rx(Math::PI/2, q)
    rz(theta, q)
    rx(-Math::PI/2, q)
  end

  def z(q)
    rz(Math::PI, q)
  end

  def y(q)
    rz(Math::PI, q)
    x(q)
  end

  def measure(q, b)
    if q >= @num_qubits
      puts 'Index for qubit out of range'
    end

    if b >= @num_clbits
      puts 'Index for output bit out of range'
    end

    @data.push(['m', q, b])
  end
end

def simulate(qc, shots, get)
  def superpose(x, y)
    r2 = 0.70710678118
    first = [(x[0] + y[0]) * r2, (x[1] + y[1]) * r2]
    second = [(x[0] - y[0]) * r2, (x[1] - y[1]) * r2]
    sup = [first, second]
    return sup
  end

  def turn(x, y, theta)
    first = [x[0] * Math.cos(theta / 2) + y[1] * Math.sin(theta / 2), x[1] * Math.cos(theta / 2) - y[0] * Math.sin(theta / 2)]
    second = [y[0] * Math.cos(theta / 2) + x[1] * Math.sin(theta / 2), y[1] * Math.cos(theta / 2) - x[0] * Math.sin(theta / 2)]
    trn = [first, second]
    return trn
  end

  k = []

  j = 0
  while j < qc.num_qubits.pow(2)
    k.push([0, 0])
    j = j + 1
  end
  k[0] = [1.0, 0.0]

  outputMap = Array.new

  for gate in qc.data

    if gate[0] == 'm'
      outputMap[gate[2]] = gate[1]
    elsif gate[0] == 'x' || gate[0] == 'h' || gate[0] == 'rx'
      j = gate.last
      
      for i0 in (0..2**j)
        for i1 in (0..2**(qc.num_qubits - j - 1))
          b0 = i0 + 2^(j+1) * i1
          b1 = b0 + 2^j
          
          if gate[0] == 'x'
            temp0 = k[b0]
            temp1 = k[b1]
            k[b0] = temp1
            k[b1] = temp0
          elsif gate[0] == 'h'
            sup = superpose(k[b0], k[b1-1]) #TODO: For some reason k[b1] does not exist, which is wrong
            k[b0] = sup[0]
            k[b1] = sup[1]
          else
            theta = gate[1]
            trn = turn(k[b0], k[b1], theta)
            k[b0] = trn[0]
            k[b1] = trn[1]
          end
        end
      end
    elsif gate[0] == 'cx'
      s = gate[1]
      t = gate[2]
      l = [s, t].min
      h = [s, t].max

      for i0 in (0..2**l)
        for i1 in (0..2**(h - l - 1))          
          for i2 in (0..2**(qc.num_qubits - h - 1)) 
            b0 = i0 + 2^(l + 1) * i1 + 2^(h + 1) * i2 + 2^s
            b1 = b0 + 2^t
            tmp0 = k[b0]
            tmp1 = k[b1]
            k[b0] = tmp1
            k[b1] = tmp0
          end
        end
      end
    end

    if get == 'statevector'
      return k
    else
      m = []
      idx_numq = 0
      while idx_numq < qc.num_qubits
        m.push(false)
        idx_numq = idx_numq + 1
      end

      for gate in qc.data        
        for j in (0..qc.num_qubits)
          if gate.last == j && m[j]
            puts 'Incorrect or missing measure command'
          end
          m[j] = (gate[0] == 'm' && gate[1] == j && gate[2] == j)
        end
      end

      probs = []

      i = 0
      #puts 'k length'
      #puts k.length()
      #puts k
      # TODO: undefined method `[]' for nil:NilClass
      while i < k.length()
        #puts i
        #puts k[i][0].class
        #puts k[i][1].class
        probs.push(k[i][0]**2 + k[i][1]**2)
        i = i + 1
      end

      # TODO:
      # This is more similar to the Python implementation, still has the same error as the above version
      # for e in k
      #   puts e
      #   probs.push(e[0]**2 + e[1]**2)
      # end

      if get == 'counts' || get == 'memory'
        me = []

        idx_shots = 0
        while idx_shots < shots
          cumu = 0.0
          un = true
          r = rand()

          j = 0
          while j < probs.length()
            p = probs[j]
            cumu = cumu + p
            if r < cumu && un
              bitStr = j.to_s(2)
              padStr = (10^(qc.num_qubits - bitStr.length())).to_s
              padStr = padStr[1, qc.num_qubits]
              rawOut = padStr + bitStr
              outList = []
              i = 0
              while i < qc.num_clbits
                outList.push('0')
                i = i + 1
              end

              for bit in outputMap
                outList[qc.num_clbits - 1 - bit] = rawOut[qc.num_qubits - 1 - outputMap[bit]]
              end

              out = outList.join("")
              me.push(out)
              un = false
            end

            j = j + 1
          end

          idx_shots = idx_shots + 1
        end
      
      elsif get == 'memory'
        return m
      else
        counts = Hash.new
        meIdx = 0
        while meIdx < me.length()
          out = me[meIdx]
          if counts[out]
            counts[out] = counts[out] + 1
          else
            counts[out] = 1
          end
          meIdx = meIdx + 1
        end
        return counts
      end
    end
  end
end


psiMinus = QuantumCircuit.new(2, 2);
psiMinus.h(0);
psiMinus.x(1);
psiMinus.cx(0, 1);
psiMinus.z(1);
psiMinus.measure(0, 0);
psiMinus.measure(1, 1);
psiMinusStatevector = simulate(psiMinus, 0, 'statevector');
puts 'psiMinusStatevector: '
puts psiMinusStatevector
puts simulate(psiMinus, 5, 'counts')