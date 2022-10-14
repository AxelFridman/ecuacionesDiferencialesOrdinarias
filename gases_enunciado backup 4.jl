### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ 5699b85e-0f55-11ed-0865-9fbd5aa9097c
begin 
	using Plots, DifferentialEquations
end

# ╔═╡ a1ce46ff-f4e1-4a84-b1d0-31c67cc7523a
begin
	using Random
	using Distributions
end

# ╔═╡ 5ba9125c-262e-4a31-9515-109463527031
md"""
# IMC

## Trabajo Práctico $n^\circ 1$: Dinámica de gases.
"""

# ╔═╡ d7d2e805-781f-4b07-9adc-9c75acc66bc9
md"""##### Criterio de corrección

El TP consta de dos partes. La primera corresponde a la implementación básica del sistema y su simulación. La impecable resolución de esta primera parte equivale a un 8. Una resolución correcta, a un 7. Para aumentar la nota, hay al final del TP algunos _**Adicionales**_. La resolución de cualquiera de los ellos alcanza para llegar al 10, si se lo resuelve de manera correcta y completa. """

# ╔═╡ 68a95dca-e8ce-4253-a068-1cd2cfac893a
md"""Queremos estudiar un sistema de muchas partículas moviéndose en una caja. Pensemos, por ejemplo, en un gas, cuyas moléculas se repelen entre sí y chocan contra las paredes. Para simplificar, trabajaremos con una caja en el plano.

#### Fuerzas

Dadas dos masas $m_i$ y $m_j$ ubicadas en los puntos de coordenadas $(x_i,y_i)$ y $(x_j,y_j)$ respectivamente, podemos modelar los choques entre ellas a través de un potencial repulsivo. Este potencial debe ser grande cuando las partículas están cerca y prácticamente nulo cuando están lejos. Proponemos, por lo tanto, un potencial de la forma:

$E^P_{ij} = k_1\frac{m_i m_j}{d_{ij}^4},$

donde $k_1$ es una constante de la interación y $d_{ij}$ es la distancia entre las partículas, es decir: 

$d_{ij}^2 = (x_i-x_j)^2+(y_i-y_j)^2.$

Con este potencial, la fuerza $F_i^j$ que la masa $j$ ejerce sobre la masa $i$ es: 

$F_i^j = -\nabla_i E^P_{ij} = 4k_1 m_i m_j \frac{(x_i,y_i)-(x_j,y_j)}{d_{ij}^6},$

mientras que $F_j^i = -F_i^j$. La fuerza total sobre la partícula $i$ será la suma de las fuerzas que todas las otras partículas ejercen sobre ella. 

#### Rebotes

Asumiremos que los choques contra las paredes conservan la energía. Los modelaremos simplemente detectando cuando una masa se sale de la caja, reflejándola hacia adentro e invirtiendo su velocidad. 

"""


# ╔═╡ 9ec881e2-3a6f-47c6-a900-40376f929f3f
md"""### Primera Parte:

Comenzaremos realizando la simulación general de este fenómeno. Asumimos que la caja es cuadrada y para reducir el número de variables definimos el lado como una variable global:"""

# ╔═╡ dbe0b543-3c51-4732-88ec-364064088380
const L = 10.0

# ╔═╡ 373f650b-86d1-45ca-aad8-613940e2f788
md"""###### Ejercicio 1:
Implementar una función que genere un dato inicial aleatorio. Es decir: que reciba un parámetro $n$ (la cantidad de partículas a generar) y devuelva alguna estructura de datos adecuada que contenga las posiciones iniciales, tomadas al azar en el cuadrado $[0,L]\times[0,L]$ y las velocidades iniciales, también tomadas al azar. 

Las velocidades pueden influir en la dinámica de las simulaciones. Por lo tanto, la recomendación es que la función reciba un parámetro de escala `V` y genere para cada partícula un ángulo al azar `α∈[0,2π)` y un valor al azar `v∈[0,V]` y defina las coordenadas de la velocidad con estos datos. De esta manera se obtienen vectores de velocidad distribuidos uniformemente en el círculo de radio `V`, y es posible modificar el valor de `V` de una simulación a otra. """

# ╔═╡ 73d3bf5e-8626-4a7f-9404-a953c59d5989
rand(Uniform(0, L))

# ╔═╡ ff6ebf08-69b3-4d3c-82b4-af70f12ddd30
# dato inicial
function generarPosicionesVelocidadesAlAzar(cantidad, pared, maxVelocidad)
	posVel = []
	for i in 1:cantidad
		posicion = [rand(Uniform(0, pared)), rand(Uniform(0, pared))]
		angulo = rand(Uniform(0, 2*π))
		modVel = rand(Uniform(0, maxVelocidad))
		velocidad = [modVel * cos(angulo), modVel * sin(angulo)]
		for j in 1:2
			push!(posVel, posicion[j])
		end
		for j in 1:2
			push!(posVel, velocidad[j])
		end
		
	end
	return posVel
end

# ╔═╡ cd6203d6-dd50-4d03-9ac1-0400e124b1e0
generarPosicionesVelocidadesAlAzar(2, L, 1)

# ╔═╡ ea76cc50-1005-4902-87f2-85ba43525134
md"""###### Ejercicio 2:

Implementar la función que define el sistema de ecuaciones. Asumir que el vector de parámetros `p` toma la forma `p=[k₁,m]`, donde `m=[m₁,m₂,…,mₙ]` es el vector de masas.
 """

# ╔═╡ caba579c-5cce-42c0-8293-19b3bbe8a1fa
 distEuclideana(x1,y1,x2,y2) = sqrt((x1-x2)^2+(y1-y2)^2)

# ╔═╡ 8a05aeea-be56-4b46-a42c-6356c2de73ed
 # ecuaciones del modelo
 function gases(du,u,pInfo,t)
	k1, masas, L, minDis = pInfo
	
	for gasIesimo in 1:Int(length(u)/4)
		Posx1 = u[(gasIesimo-1)*4 + 1]
		Posy1 = u[(gasIesimo-1)*4 + 2]
		Velx1 = u[(gasIesimo-1)*4 + 3]
		Vely1 = u[(gasIesimo-1)*4 + 4]

		du[(gasIesimo-1)*4 + 1] = Velx1
		du[(gasIesimo-1)*4 + 2] = Vely1
		du[(gasIesimo-1)*4 + 3] = 0.
		du[(gasIesimo-1)*4 + 4] = 0.
	
		for gasOtro in 1:Int(length(u)/4)
			
			Posx2 = u[(gasOtro-1)*4 + 1]
			Posy2 = u[(gasOtro-1)*4 + 2]
			Velx2 = u[(gasOtro-1)*4 + 3]
			Vely2 = u[(gasOtro-1)*4 + 4]
				
			distEntrePlanetas = distEuclideana(Posx1, Posy1, Posx2, Posy2)
			
			if(distEntrePlanetas > minDis)
				du[(gasIesimo-1)*4 + 3] = du[(gasIesimo-1)*4 + 3] -
				4*k1*masas[gasOtro]*masas[gasIesimo]*(Posx2-Posx1)/(distEntrePlanetas^6)
					
				du[(gasIesimo-1)*4 + 4] = du[(gasIesimo-1)*4 + 4] -
				4*k1*masas[gasOtro]*masas[gasIesimo]*(Posy2-Posy1)/(distEntrePlanetas^6)
				
					
			end
			
			
		end
	end
end

# ╔═╡ 239075d6-fde1-4794-825c-1bd4e9380681
md"""###### Ejercicio 3:

Para reconocer los choques contra las paredes utilizaremos un `DiscreteCallback`. Implementar:
1. La condición, que debe devolver `true` cuando cualquiera de las particulas está fuera de la caja.
2. La función de rebote, que debe reconocer todas las partículas fuera de la caja y corregir sus posiciones y velocidades.

Esto puede hacerse implementando una única condición, implementando dos (una para choques en $x$ y otra para choques en $y$), o implementando cuatro (una por cada borde). Lo importante es que, en cualquier caso, cada condición debe revisar _todas_ las partículas. Para esto puede resultar útil el comando `any`, que recibe un vector de variables booleanas y devuelve `true` si alguna de sus coordenadas es `true`. """

# ╔═╡ c21a9f39-518c-4fbc-af2f-db27e33a2d1d
# condición
begin
	
function condicionChoqueIzq(u,t,integrator)
	for gas in 1:Int(length(u)/4)
			Posx = u[(gas-1)*4 + 1]
			if(Posx<0)
				return true
			end
	end
	return false
end

function condicionChoquePiso(u,t,integrator)
	for gas in 1:Int(length(u)/4)
			Posy = u[(gas-1)*4 + 2]
			if(Posy<0)
				return true
			end
	end
	return false
end

function condicionChoqueDer(u,t,integrator)
	for gas in 1:Int(length(u)/4)
			Posx = u[(gas-1)*4 + 1]
			if(Posx > integrator.p[3]) #ACA HAY QUE PONER LA L !!!!!!!!!
				return true
			end
	end
	return false
end

function condicionChoqueTecho(u,t,integrator)
	for gas in 1:Int(length(u)/4)
			Posy = u[(gas-1)*4 + 2]
			if(Posy > integrator.p[3]) #ACA HAY QUE PONER LA L !!!!!!!!!
				return true
			end
	end
	return false
end
	
end

# ╔═╡ cb7222c4-4530-4c25-9123-894a0ae7a184
# rebotes
begin

function respuestaChoqueIzq!(integrator)
	for gas in 1:Int(length(integrator.u)/4)
			Posx = integrator.u[(gas-1)*4 + 1]
			if(Posx<0)
				integrator.u[(gas-1)*4 + 3] = -integrator.u[(gas-1)*4 + 3]
				integrator.u[(gas-1)*4 + 1]  = 0 - (integrator.u[(gas-1)*4 + 1]  - 0)
			end
	end
end
function respuestaChoquePiso!(integrator)
	for gas in 1:Int(length(integrator.u)/4)
			Posy = integrator.u[(gas-1)*4 + 2]
			if(Posy<0)
				integrator.u[(gas-1)*4 + 4] = -integrator.u[(gas-1)*4 + 4]
				integrator.u[(gas-1)*4 + 2] = 0 - (integrator.u[(gas-1)*4 + 2] - 0)
			end
	end
end
function respuestaChoqueDer!(integrator)
	for gas in 1:Int(length(integrator.u)/4)
			Posx = integrator.u[(gas-1)*4 + 1]
			if(Posx>integrator.p[3])
				integrator.u[(gas-1)*4 + 3] = -integrator.u[(gas-1)*4 + 3]
				integrator.u[(gas-1)*4 + 1] = integrator.p[3] - (integrator.u[(gas-1)*4 + 1] -integrator.p[3])
			end
	end
end
function respuestaChoqueTecho!(integrator)
	for gas in 1:Int(length(integrator.u)/4)
			Posy = integrator.u[(gas-1)*4 + 2]
			if(Posy>integrator.p[3])
				integrator.u[(gas-1)*4 + 4] = -integrator.u[(gas-1)*4 + 4]
				integrator.u[(gas-1)*4 + 2] = integrator.p[3] - (integrator.u[(gas-1)*4 + 2] -integrator.p[3])
			end
	end
end

end

# ╔═╡ 10cfbe02-510c-4d52-9133-d51adb26deb2
begin
	dc1 = DiscreteCallback(condicionChoqueIzq,respuestaChoqueIzq!)
	dc2 = DiscreteCallback(condicionChoqueDer,respuestaChoqueDer!)
	dc3 = DiscreteCallback(condicionChoquePiso,respuestaChoquePiso!)
	dc4 = DiscreteCallback(condicionChoqueTecho,respuestaChoqueTecho!)
	cbsetSala = CallbackSet(dc1,dc2,dc3,dc4)
end

# ╔═╡ 0515150e-6e13-4cc4-b68f-61708a3cf4f4
md""" ###### Ejercicio 4:

Implementar una función que reciba un conjunto de parámetros adecuados y ejecute una simulación. Verificar que se ejecuta sin errores simulando un sistema con dos partículas. """



# ╔═╡ d74f8588-a7da-4001-8bea-e981bfdbd61b
function generarMasasAlAzar(cantidad, minMasa, maxMasa)
	masas = []
	for i in 1:cantidad
		masa = rand(Uniform(minMasa, maxMasa))
		push!(masas, masa)
	end
	return masas
end

# ╔═╡ 9da98062-6c3b-49e3-8b96-92dcc89769c7
# simulación
begin
	k1 = float.(10.0e-6)
	n = 5
	masas = float.(generarMasasAlAzar(n, 1, 1.01))
	tIni = 0
	tFin = 20
	tspan = [tIni,tFin]
	datoInicialEspacial = float.(generarPosicionesVelocidadesAlAzar(n, L, 3))
	#datoInicialEspacial = float.([1,1,0,0,0.1,0.1,0,0,1,0,0,0])
	pInfo = float.([k1, masas, L, 0.01])
	Pgas  = ODEProblem(gases,datoInicialEspacial,tspan,pInfo)
	solCuerpos = solve(Pgas, callback=cbsetSala,dtmax=0.1) #callback=cbsetSala

end

# ╔═╡ 47b8fa14-6162-49c6-9d21-4b4d0ae09de2
solCuerpos.u

# ╔═╡ 316fd5e6-f050-46db-8239-a39ee7a2a593
begin
	plot(solCuerpos,idxs=[(i,i+1) for i in 1:4:n*4])
	plot!([0,0,L,L,0],[0,L,L,0,0], label="pared")
end

# ╔═╡ a8f21b8d-f99e-4b51-91cd-981a99ac1a27
md"""
Aca podemos ver las trayectorias de las particuas y percibir (a ojo) que estan rebotando correctamente. 
"""

# ╔═╡ d1ede4d9-0d7b-43c2-aeb7-cf45a7f1d044
begin
	cantFrames = 100
	rangoTiempo = tIni: (tFin-tIni)/cantFrames : tFin
	vectorTiempos = zeros(cantFrames)
	for i in 1:cantFrames
		vectorTiempos[i] = rangoTiempo[i]
		
	end
	solCuerpos2 = solCuerpos(vectorTiempos)
end

# ╔═╡ a1524118-a9ac-46c4-a2cb-f54ca214c59c
begin
	animacion = @animate for i in 1:length(solCuerpos2[1,:])
		difPared = 0.5
		plot(xlims=(0-difPared,L+difPared),ylims=(0-difPared,L+difPared))
		for j in 1:4:(n)*4
			scatter!([solCuerpos2[j,i]], [solCuerpos2[j+1,i]], markersize=3*masas[Int(1+(j-1)/4)], legend=:none)
			plot!([0,0,L,L,0],[0,L,L,0,0], label="pared")
		end
	end
end

# ╔═╡ a5fa4f83-3169-4268-b816-7b8fe2c5333a
md"""###### Ejercicio 5:

Para visualizar los resultados implementar una función que reciba la solución de una simulación y realice una animación. Cada cuadro de la animación debe contener las líneas que delimitan la caja y un scatter plot de las posiciones de las masas en un instante determinado. 

Tomando $k_1 = 10^{-6}$ y masas iguales a 1 realizar simulaciones con 2, 5 y 10 partículas. Experimentar con distintas velocidades iniciales y comprobar que las interacciones entre partículas y los choques con las paredes se realicen correctamente. Para evitar problemas de precisión puede llegar a ser necesario fijar tolerancias menores a las estándar. Tener en cuenta que tolerancias muy chicas aumentan el tiempo de ejecución: es necesario hacer un balance. Realizar una simulación con 50 partículas y si es posible con 100. 

Es interesante también estudiar el caso en que las masas son variables. Simular un ejemplo con masas aleatorias (digamos, entre $0.5$ y $2.5$). Para visualizar la simulación con mayor claridad es recomendable graficar los puntos con distintos tamaños, escalados de acuerdo a su masa. Para ello, utilizar el parámetro `markersize` de `scatter`."""

# ╔═╡ 35f58720-56f4-4cce-adab-95414062f3d0
# animación
mp4(animacion ) #"videoParticulas.mp4"

# ╔═╡ 223a382a-3ebb-43f6-9773-c48ebd3e0569
md"""
En esta animacion podemos ver como actua nuestro gas ficticio. Podemos ver como rebotan elasticamente con las paredes y como levemente interactuan las particulas entre si. ¡Logramos modelar un gas!
"""

# ╔═╡ e606d381-d37e-414d-9c68-c65205e61873
# funcion para animar
function generarAnimacion(funcion, n, minMasa, maxMasa, maxVel, tIni, tFin, L, k1, k2, cantFrames)
	masas = float.(generarMasasAlAzar(n, minMasa, maxMasa))
	tspan = [tIni,tFin]
	datoInicialEspacial = float.(generarPosicionesVelocidadesAlAzar(n, L, maxVel))
	pInfo = float.([k1, masas, L, 0.01, k2])
	Pgas  = ODEProblem(funcion,datoInicialEspacial,tspan,pInfo)
	solCuerpos = solve(Pgas, callback=cbsetSala,dtmax=0.1)
	rangoTiempo = tIni: (tFin-tIni)/cantFrames : tFin
	vectorTiempos = zeros(cantFrames)
	for i in 1:cantFrames
		vectorTiempos[i] = rangoTiempo[i]
		
	end
	solCuerpos2 = solCuerpos(vectorTiempos)
	animacion = @animate for i in 1:length(solCuerpos2[1,:])
		difPared = 0.5
		plot(xlims=(0-difPared,L+difPared),ylims=(0-difPared,L+difPared))
		for j in 1:4:(n)*4
			scatter!([solCuerpos2[j,i]], [solCuerpos2[j+1,i]], markersize=3*masas[Int(1+(j-1)/4)], legend=:none)
			plot!([0,0,L,L,0],[0,L,L,0,0], label="pared")
		end
	end
	return animacion
end


# ╔═╡ bf1f9690-6dda-4a1f-8d6d-377360878fab
begin
	# 5 particulas
	anm = generarAnimacion(gases, 5, 1, 1.01, 3, 0, 20, L, k1, 0, 100)
	mp4(anm )
end

# ╔═╡ 33c3a10f-0527-4a04-9851-9b43560f501c
md"""
Parece todo controlado. No hay mucha interaccion entre las particulas.
"""

# ╔═╡ 8abdec27-c63a-4b4f-ade9-0cfa674b22dd
begin
	# 10 particulas
	anm2 = generarAnimacion(gases, 10, 1, 1.01, 3, 0, 20, L, k1, 0,100)
	mp4(anm2 )
end

# ╔═╡ df275c47-7936-442e-9771-5c9c4cb6e46f
md"""
Ya es posible observar algunas interacciones entre las particulas.
"""

# ╔═╡ ecd0f578-2614-4473-af25-0db650688a06
# prueba con 50 o 100
begin
	# 100 particulas
	anm3 = generarAnimacion(gases, 100, 1, 1.01, 3, 0, 20, L, k1, 0, 100)
	mp4(anm3 )
end

# ╔═╡ 605d0f30-3039-4cd3-93d8-852b5e0ba141
md"""
Ahora podemos ver una constante interaccion en cada una de las particulas.
"""

# ╔═╡ 29da6749-52fb-4881-88d8-556613629dac
# prueba con 50 o 100 de masas distintas
begin
	# 50 particulas masas distintas
	anm4 = generarAnimacion(gases, 50, 1, 4.01, 3, 0, 20, L, k1, 0, 100)
	mp4(anm4 )
end

# ╔═╡ b5832d59-7550-4899-83a5-3ee111cda9c0
md"""
Se logra ver como las particulas con menos masa son mas faciles de cambiar su trayectoria.
"""

# ╔═╡ c0924df8-3a8f-4923-b341-e77e692fcb84
md"""##### Adicionales:

###### Fuerzas adicionales:

Podemos agregar al sistema fuerzas de atracción que actúen a distancias intermedias. De este modo, si dos partículas están muy lejos una de otra prácticamente no interactúan, si están menos lejos se atraen y si están muy cerca se repelen. Por ejemplo, podemos considerar un potencial  de la forma: 

$E^P_{ij} = k_1 \frac{m_1m_2}{d_{ij}^4} - k_2 \frac{m_1m_2}{d_{ij}^3},$

donde el primer término es el mismo con el que trabajamos previamente y el segundo es atractivo. Experimentar con distintos valores de $k_2$ y de las velocidades iniciales, buscando que se formen cúmulos de partículas (pequeños o grandes). Para ello, resulta útil deducir la distancia de equilibrio entre dos partículas (que depende de $k_1$ y $k_2$). 

También se puede agregar al sistema una fuerza gravitatoria (aunque dadas las magnitudes que estamos manejando, debería ser inferior a la gravitación usual).

Realizar simulaciones con masas iguales y con masas variables."""

# ╔═╡ 84d5d1f3-3592-470b-a75d-c210cbfd8171
function gasesAtractivo(du,u,pInfo,t)
	k1, masas, L, minDis, k2 = pInfo
	
	for gasIesimo in 1:Int(length(u)/4)
		Posx1 = u[(gasIesimo-1)*4 + 1]
		Posy1 = u[(gasIesimo-1)*4 + 2]
		Velx1 = u[(gasIesimo-1)*4 + 3]
		Vely1 = u[(gasIesimo-1)*4 + 4]

		du[(gasIesimo-1)*4 + 1] = Velx1
		du[(gasIesimo-1)*4 + 2] = Vely1
		du[(gasIesimo-1)*4 + 3] = 0.
		du[(gasIesimo-1)*4 + 4] = 0.
	
		for gasOtro in 1:Int(length(u)/4)
			
			Posx2 = u[(gasOtro-1)*4 + 1]
			Posy2 = u[(gasOtro-1)*4 + 2]
			Velx2 = u[(gasOtro-1)*4 + 3]
			Vely2 = u[(gasOtro-1)*4 + 4]
				
			distEntreGases = distEuclideana(Posx1, Posy1, Posx2, Posy2)
			
			if(distEntreGases > minDis)
				du[(gasIesimo-1)*4 + 3] = du[(gasIesimo-1)*4 + 3] -
				4*k1*masas[gasOtro]*masas[gasIesimo]*(Posx2-Posx1)/(distEntreGases^6)+
				3*k2*masas[gasOtro]*masas[gasIesimo]*(Posx2-Posx1)/(distEntreGases^5)
					
				du[(gasIesimo-1)*4 + 4] = du[(gasIesimo-1)*4 + 4] -
				4*k1*masas[gasOtro]*masas[gasIesimo]*(Posy2-Posy1)/(distEntreGases^6)+
				3*k2*masas[gasOtro]*masas[gasIesimo]*(Posy2-Posy1)/(distEntreGases^5)
				
					
			end
			
			
		end
	end
end

# ╔═╡ 382ec6b5-4560-4579-9886-040816d786f4
begin
	# 10 particulas masas distintas, atrayendo
	k22 = 1e-4
	k11 = 1e-5
	tFinal = 80
	maxVel = 2
	anm5 = generarAnimacion(gasesAtractivo,10 , 1, 4.01, maxVel, 0, tFinal, L, k11, k22, 400)
		#5, 1, 3.01, 0, 100, L, k11, k22, 600)
	mp4(anm5 )
end

# ╔═╡ 3d5b13b8-fb58-463b-ad6c-782f110f7126
md"""
Suceden varias cosas muy interesantes, por un lado las particulas comienzan moviendose relativamente lento pero al estar a una distancia mayor que una distancia "D" donde las fuerzas se equilibran empiezan a atraerse. Luego se siguen atrayendo pero como tienen momento traspasan esta distancia D de equilibrio y ahora la fuerza primaria pasa a ser la de repuslion. Pero para el momento cuando comienzan a alejarse nuevamente las particulas ya estan tan cerca que la fuerza de rechazo es inmensa. Lo cual explica como la energia cinetica del sistema crece increiblemente, ya que al principio del sistema tienen una energia potencial gigante (aunque no lo parezca).

"""

# ╔═╡ 2165ddff-931b-418c-9593-dea517d0b97f


# ╔═╡ 70eb4406-cb25-4d69-abbb-ab2555b5ec1f
md"""###### Energía:

Dado que nuestras fuerzas son conservativas es interesante verificar si la energía del sistema se conserva. La energía total viene dada por:

$E = \sum_{i,j} E_{ij}^P + \sum_i E_i^C,$

donde $E_i^C$ es la energía cinética de la partícula $i$:

$E_i^C = \frac{1}{2}m_i|v_i|^2.$

Implementar funciones que calculen la energía potencial y la energía cinética para un instante de tiempo dado. Computar la energía total de una solución a lo largo del tiempo y graficarla. ¿Es constante? Si no lo es, ¿qué se puede hacer para lograr que sea constante? Graficar también cada energía por separado.

"""

# ╔═╡ 3a6d1ded-a7f3-403c-83e4-79800a5caf62
e_cinetica_particula(m,v) = 1/2 *m* (v[1]^2 + v[2]^2)^(1/2)    

# ╔═╡ 35079b88-7f36-41e2-bfe0-8a261cb53cf6
begin
	t_0 = solCuerpos(100)
	Posx1 = zeros(Int(length(t_0)/4))
	Posy1 = zeros(Int(length(t_0)/4))
	Velx1 = zeros(Int(length(t_0)/4))
	Vely1 = zeros(Int(length(t_0)/4))
	
	for gasIesimo in 1:Int(length(t_0)/4)
		Posx1[gasIesimo] = t_0[(gasIesimo-1)*4 + 1]
		Posy1[gasIesimo] = t_0[(gasIesimo-1)*4 + 2]
		Velx1[gasIesimo] = t_0[(gasIesimo-1)*4 + 3]
		Vely1[gasIesimo] = t_0[(gasIesimo-1)*4 + 4]
	end
	masasCinetica = pInfo[2]
end

# ╔═╡ 7618d869-956d-4f8d-898d-328809e05799
function energiaCinetica(masas, Velx, Vely)
		res = 0
		for i in 1:length(masas)
			velx_i = Velx[i]
			vely_i = Vely[i]
			res = res + e_cinetica_particula(masas[i], [velx_i, vely_i])
		
		end
		return res
end

# ╔═╡ 549b7fd4-398a-4571-aec6-796aa9f6d009
energiaCinetica(masasCinetica, Velx1, Vely1)

# ╔═╡ a578169c-242a-4f61-9f36-4b61b0b6f1a4
function energiaCinetica_t(masas, t, sol)
		t_0 = sol(t)
		Velx1 = zeros(Int(length(t_0)/4))
		Vely1 = zeros(Int(length(t_0)/4))
		for gasIesimo in 1:Int(length(t_0)/4)
			Velx1[gasIesimo] = t_0[(gasIesimo-1)*4 + 3]
			Vely1[gasIesimo] = t_0[(gasIesimo-1)*4 + 4]
		end
		return energiaCinetica(masas, Velx1,Vely1)
end

# ╔═╡ f55155e9-5652-4ac2-8af8-be28407d89bc
energiaCinetica_t(masasCinetica, 3, solCuerpos)

# ╔═╡ 4365210a-3929-4407-a43f-2068cf1cf3a3
begin
t_ = 0:0.5:100

end

# ╔═╡ 02fe3358-f2c4-4b6e-b616-a3cbaed1ae96
length(t_)

# ╔═╡ 9e1c764f-b974-40f2-a20d-46974932a9b9
function potencialSistema(masas, t, solCuerpos, k1)
	solCuerpos = solCuerpos(t)
	cantCol = length(solCuerpos)
	energiaSistema = 0 
	for gasIesimo in 1:Int(cantCol/4)
		Posx1 = solCuerpos[(gasIesimo-1)*4 + 1]
		Posy1 = solCuerpos[(gasIesimo-1)*4 + 2]
		Velx1 = solCuerpos[(gasIesimo-1)*4 + 3]
		Vely1 = solCuerpos[(gasIesimo-1)*4 + 4]
	
		for gasOtro in 1:Int(cantCol/4)
			
			Posx2 = solCuerpos[(gasOtro-1)*4 + 1]
			Posy2 = solCuerpos[(gasOtro-1)*4 + 2]
			Velx2 = solCuerpos[(gasOtro-1)*4 + 3]
			Vely2 = solCuerpos[(gasOtro-1)*4 + 4]
				
			distEntreGases = distEuclideana(Posx1, Posy1, Posx2, Posy2)

			if(gasOtro != gasIesimo)
				energiaSistema = energiaSistema + masas[gasIesimo]*masas[gasOtro]*k1/(distEntreGases^4)
			end
		end
	end
	return energiaSistema
			
end

# ╔═╡ 33c69cfe-f780-4b4a-8c18-4d66cfbf8c3e
potencialSistema(masasCinetica, 100, solCuerpos, k11)

# ╔═╡ c4ad6249-a53d-4163-b440-3beb34547268
begin
	t_res = zeros(20)
	t_resPot = zeros(20)
	tt = zeros(20)
	for i in 1:20
		tt[i] = i
		t_res[i] = energiaCinetica_t(masasCinetica, t_[i], solCuerpos)
		t_resPot[i] = potencialSistema(masasCinetica,  t_[i], solCuerpos, k11)
	end
end

# ╔═╡ 32b5c382-b93c-45cd-af18-5edbd7179f61
begin
	plot(tt,t_res, label="Energia cinetica")
	plot!( tt, t_resPot, label="Energia potencial")
	plot!( tt, t_res+t_resPot, label="Energia total")
end

# ╔═╡ d1c325ed-b1b9-4cad-b9d4-da41c77fdf6b
md"""
La energia se ve mas o menos constante, despues explota. No encontramos la causa precisa.
"""

# ╔═╡ 8d702baa-8fb4-4ef4-ad31-b10404243a2e
md"""###### Presión:

La presión a la que se encuentra el gas es proporcional a la cantidad de rebotes de partículas contra las paredes de la caja. Modificar los programas de manera que: 

1. El parámetro p incluya una variable adicional que funcionará como contador.
2. Cuando se realice una acción de rebote, se sume 1 al contador. 

El parámetro `p` es modificado por el solver, de modo que luego de resolver puede recuperarse el número de choques. 

Implementar funciones que resuelvan el sistema: 

1. Con distinto número de partículas y cota de velocidad inicial fija. Hacer varias simulaciones para cada cantidad de partículas, para generar estadística. Graficar la cantidad de choques contra las paredes en función del número de partículas.
2. Con un número fijo de partículas y cota de velocidad inicial variable. Hacer varias simulaciones para cada cota de velocidad. Graficar la cantidad de choques contra las paredes en función de la cota para la velocidad."""



# ╔═╡ 7cde7ad7-a15b-4cde-a284-e8cea08b3a68
md"""

"""

# ╔═╡ 60771243-3d3d-454e-94b9-08c7f25bfe87
function gasesPresion(du,u,pInfo,t)
	k1, masas, L, minDis, choques = pInfo
	
	for gasIesimo in 1:Int(length(u)/4)
		Posx1 = u[(gasIesimo-1)*4 + 1]
		Posy1 = u[(gasIesimo-1)*4 + 2]
		Velx1 = u[(gasIesimo-1)*4 + 3]
		Vely1 = u[(gasIesimo-1)*4 + 4]

		du[(gasIesimo-1)*4 + 1] = Velx1
		du[(gasIesimo-1)*4 + 2] = Vely1
		du[(gasIesimo-1)*4 + 3] = 0.
		du[(gasIesimo-1)*4 + 4] = 0.
	
		for gasOtro in 1:Int(length(u)/4)
			
			Posx2 = u[(gasOtro-1)*4 + 1]
			Posy2 = u[(gasOtro-1)*4 + 2]
			Velx2 = u[(gasOtro-1)*4 + 3]
			Vely2 = u[(gasOtro-1)*4 + 4]
				
			distEntrePlanetas = distEuclideana(Posx1, Posy1, Posx2, Posy2)
			
			if(distEntrePlanetas > minDis)
				du[(gasIesimo-1)*4 + 3] = du[(gasIesimo-1)*4 + 3] -
				4*k1*masas[gasOtro]*masas[gasIesimo]*(Posx2-Posx1)/(distEntrePlanetas^6)
					
				du[(gasIesimo-1)*4 + 4] = du[(gasIesimo-1)*4 + 4] -
				4*k1*masas[gasOtro]*masas[gasIesimo]*(Posy2-Posy1)/(distEntrePlanetas^6)
				
					
			end
			
			
		end
	end
	global contadorChoque
	contadorChoque = choques
end

# ╔═╡ 5329928c-fa5c-4352-ae30-75166f4ba9b6
begin

function respuestaChoqueIzq2!(integrator)
	for gas in 1:Int(length(integrator.u)/4)
			Posx = integrator.u[(gas-1)*4 + 1]
			if(Posx<0)
				integrator.u[(gas-1)*4 + 3] = -integrator.u[(gas-1)*4 + 3]
				integrator.u[(gas-1)*4 + 1]  = 0 - (integrator.u[(gas-1)*4 + 1]  - 0)
				integrator.p[5] = integrator.p[5] + 1
			end
	end
end
function respuestaChoquePiso2!(integrator)
	for gas in 1:Int(length(integrator.u)/4)
			Posy = integrator.u[(gas-1)*4 + 2]
			if(Posy<0)
				integrator.u[(gas-1)*4 + 4] = -integrator.u[(gas-1)*4 + 4]
				integrator.u[(gas-1)*4 + 2] = 0 - (integrator.u[(gas-1)*4 + 2] - 0)
				integrator.p[5] = integrator.p[5] + 1
			end
	end
end
function respuestaChoqueDer2!(integrator)
	for gas in 1:Int(length(integrator.u)/4)
			Posx = integrator.u[(gas-1)*4 + 1]
			if(Posx>integrator.p[3])
				integrator.u[(gas-1)*4 + 3] = -integrator.u[(gas-1)*4 + 3]
				integrator.u[(gas-1)*4 + 1] = integrator.p[3] - (integrator.u[(gas-1)*4 + 1] -integrator.p[3])
				integrator.p[5] = integrator.p[5] + 1
			end
	end
end
function respuestaChoqueTecho2!(integrator)
	for gas in 1:Int(length(integrator.u)/4)
			Posy = integrator.u[(gas-1)*4 + 2]
			if(Posy>integrator.p[3])
				integrator.u[(gas-1)*4 + 4] = -integrator.u[(gas-1)*4 + 4]
				integrator.u[(gas-1)*4 + 2] = integrator.p[3] - (integrator.u[(gas-1)*4 + 2] -integrator.p[3])
				integrator.p[5] = integrator.p[5] + 1
			end
	end
end

end

# ╔═╡ 6b9793c6-d42e-4be6-b99f-d7792c83b493
begin
	dc12 = DiscreteCallback(condicionChoqueIzq,respuestaChoqueIzq2!)
	dc22 = DiscreteCallback(condicionChoqueDer,respuestaChoqueDer2!)
	dc32 = DiscreteCallback(condicionChoquePiso,respuestaChoquePiso2!)
	dc42 = DiscreteCallback(condicionChoqueTecho,respuestaChoqueTecho2!)
	cbsetSala2 = CallbackSet(dc12,dc22,dc32,dc42)
end

# ╔═╡ ca8880e3-70df-432c-a30d-9bb85163bc9d
begin
	kPresion = float.(10.0e-6)
	nPresion = 5
	masasPresion = float.(generarMasasAlAzar(nPresion, 1, 1.01))
	tIniPresion = 0
	tFinPresion = 10
	tspanPresion = [tIniPresion,tFinPresion]
	datoInicialEspacialPresion = float.(generarPosicionesVelocidadesAlAzar(nPresion, L, 3))
	pInfoPresion = float.([kPresion, masasPresion, L, 0.01, 0])
	PgasPresion  = ODEProblem(gasesPresion,datoInicialEspacialPresion,tspanPresion,pInfoPresion)
	solPresion = solve(PgasPresion, callback=cbsetSala2,dtmax=0.1)
	
end

# ╔═╡ 99c0d98a-65e2-43d4-9a50-1f7399f121ec
md"""
Aca al correr esta celda se puede ver cuantos choques hubo en la ultima iteracion:
"""

# ╔═╡ bf740022-9c97-456b-8072-7500d52bf704
contadorChoque

# ╔═╡ c9719d0a-ba5a-4873-ab3c-ce263e0c8438
function dameChoquesMvecesNparticulas(n,m)
	res = zeros(m)
	for i in 1:m
		kPresion = float.(10.0e-6)
		nPresion = n
		masasPresion = float.(generarMasasAlAzar(nPresion, 1, 1.01))
		tIniPresion = 0
		tFinPresion = 30
		tspanPresion = [tIniPresion,tFinPresion]
		datoInicialEspacialPresion = float.(generarPosicionesVelocidadesAlAzar(nPresion, L, 3))
		pInfoPresion = float.([kPresion, masasPresion, L, 0.01, 0])
		PgasPresion  = ODEProblem(gasesPresion,datoInicialEspacialPresion,tspanPresion,pInfoPresion)
		solPresion = solve(PgasPresion, callback=cbsetSala2,dtmax=0.1)
		res[i] = contadorChoque
	end
	return res
end

# ╔═╡ 18de5b83-20e6-46e6-bd83-8f7945937198
md"""
Parte 1, vel inicial fija, moviendo cantidad de particulas hacer estadistica. Promediamos 10 simulaciones de una misma cantidad de particulas, poe cada cantidad de particulas
"""

# ╔═╡ 9b9ec907-d4b6-44f0-b638-bafb75352d20
begin
	testchoques = zeros(15)
	for i in 1:15
		testchoques[i] = mean(dameChoquesMvecesNparticulas(i, 10))
	end
end

# ╔═╡ 93c553ee-9938-4119-aa91-803823af0def
plot(1:15, testchoques, label = "cantidad de choques", xlab="Cantidad de particulas", ylab="Cantidad de choques")

# ╔═╡ fac222c7-ca4a-44ae-a966-d68fac57f0c5
md"""
Parte 2, cantidad de choques con cantidad de particulas fija en 5 pero velocidad inical 
"""

# ╔═╡ 3218a55b-5ebe-4ffa-a4b8-3e93c89c3e0d
function dameChoquesMvecesNvelIni(n,m)
	res = zeros(m)
	for i in 1:m
		kPresion = float.(10.0e-6)
		nPresion = 5
		masasPresion = float.(generarMasasAlAzar(nPresion, 1, 1.01))
		tIniPresion = 0
		tFinPresion = 30
		tspanPresion = [tIniPresion,tFinPresion]
		datoInicialEspacialPresion = float.(generarPosicionesVelocidadesAlAzar(nPresion, L, n))
		pInfoPresion = float.([kPresion, masasPresion, L, 0.01, 0])
		PgasPresion  = ODEProblem(gasesPresion,datoInicialEspacialPresion,tspanPresion,pInfoPresion)
		solPresion = solve(PgasPresion, callback=cbsetSala2,dtmax=0.1)
		res[i] = contadorChoque
	end
	return res
end

# ╔═╡ 9cdd578d-d448-4eac-a976-39a1b7340993
begin
	testchoquesVel = zeros(20)
	for i in 1:20
		testchoquesVel[i] = mean(dameChoquesMvecesNvelIni(i, 10))
	end
end

# ╔═╡ 58da3aed-b3f6-441c-ac4b-274d36a247d5
plot(1:20, testchoquesVel, label = "cantidad de choques", xlab="velocidad inicial max", ylab="Cantidad de choques")

# ╔═╡ 903f4520-35ca-41d4-8ebc-bca57d59d329
md"""
	Conclusion: tanto como la velocidad como la cantidad de particulas hacen crecer linealmente la cantidad de choques, pero aun generando promedio de 10 siguen siendo bastante ruidosos e irregulares.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DifferentialEquations = "0c46a032-eb83-5123-abaf-570d42b7fbaa"
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[compat]
DifferentialEquations = "~7.5.0"
Distributions = "~0.25.75"
Plots = "~1.34.4"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.3"
manifest_format = "2.0"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "195c5505521008abea5aee4f96930717958eac6f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.4.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[deps.ArrayInterface]]
deps = ["ArrayInterfaceCore", "Compat", "IfElse", "LinearAlgebra", "Static"]
git-tree-sha1 = "d6173480145eb632d6571c148d94b9d3d773820e"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "6.0.23"

[[deps.ArrayInterfaceCore]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "5bb0f8292405a516880a3809954cb832ae7a31c5"
uuid = "30b0a656-2188-435a-8636-2ec0e6a096e2"
version = "0.1.20"

[[deps.ArrayInterfaceGPUArrays]]
deps = ["Adapt", "ArrayInterfaceCore", "GPUArraysCore", "LinearAlgebra"]
git-tree-sha1 = "fc114f550b93d4c79632c2ada2924635aabfa5ed"
uuid = "6ba088a2-8465-4c0a-af30-387133b534db"
version = "0.2.2"

[[deps.ArrayInterfaceOffsetArrays]]
deps = ["ArrayInterface", "OffsetArrays", "Static"]
git-tree-sha1 = "c49f6bad95a30defff7c637731f00934c7289c50"
uuid = "015c0d05-e682-4f19-8f0a-679ce4c54826"
version = "0.1.6"

[[deps.ArrayInterfaceStaticArrays]]
deps = ["Adapt", "ArrayInterface", "ArrayInterfaceStaticArraysCore", "LinearAlgebra", "Static", "StaticArrays"]
git-tree-sha1 = "efb000a9f643f018d5154e56814e338b5746c560"
uuid = "b0d46f97-bff5-4637-a19a-dd75974142cd"
version = "0.1.4"

[[deps.ArrayInterfaceStaticArraysCore]]
deps = ["Adapt", "ArrayInterfaceCore", "LinearAlgebra", "StaticArraysCore"]
git-tree-sha1 = "a1e2cf6ced6505cbad2490532388683f1e88c3ed"
uuid = "dd5226c6-a4d4-4bc7-8575-46859f9c95b9"
version = "0.1.0"

[[deps.ArrayLayouts]]
deps = ["FillArrays", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "ac5cc6021f32a272ee572dd2a325049a1fa0d034"
uuid = "4c555306-a7a7-4459-81d9-ec55ddd5c99a"
version = "0.8.11"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.BandedMatrices]]
deps = ["ArrayLayouts", "FillArrays", "LinearAlgebra", "Random", "SparseArrays"]
git-tree-sha1 = "d37d493a1fc680257f424e656da06f4704c4444b"
uuid = "aae01518-5342-5314-be14-df237901396f"
version = "0.17.7"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BitFlags]]
git-tree-sha1 = "84259bb6172806304b9101094a7cc4bc6f56dbc6"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.5"

[[deps.BitTwiddlingConvenienceFunctions]]
deps = ["Static"]
git-tree-sha1 = "eaee37f76339077f86679787a71990c4e465477f"
uuid = "62783981-4cbd-42fc-bca8-16325de8dc4b"
version = "0.1.4"

[[deps.BoundaryValueDiffEq]]
deps = ["BandedMatrices", "DiffEqBase", "FiniteDiff", "ForwardDiff", "LinearAlgebra", "NLsolve", "Reexport", "SciMLBase", "SparseArrays"]
git-tree-sha1 = "2f80b70bd3ddd9aa3ec2d77604c1121bd115650e"
uuid = "764a87c0-6b3e-53db-9096-fe964310641d"
version = "2.9.0"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CEnum]]
git-tree-sha1 = "eb4cb44a499229b3b8426dcfb5dd85333951ff90"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.2"

[[deps.CPUSummary]]
deps = ["CpuId", "IfElse", "Static"]
git-tree-sha1 = "9bdd5aceea9fa109073ace6b430a24839d79315e"
uuid = "2a0fbf3d-bb9c-48f3-b0a9-814d99fd7ab9"
version = "0.1.27"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "e7ff6cadf743c098e08fca25c91103ee4303c9bb"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.6"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "38f7a08f19d8810338d4f5085211c7dfa5d5bdd8"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.4"

[[deps.CloseOpenIntervals]]
deps = ["ArrayInterface", "Static"]
git-tree-sha1 = "5522c338564580adf5d58d91e43a55db0fa5fb39"
uuid = "fb6a15b2-703c-40df-9091-08a04967cfa9"
version = "0.1.10"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "1fd869cc3875b57347f7027521f561cf46d1fcd8"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.19.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "d08c20eef1f2cbc6e60fd3612ac4340b89fea322"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.9"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.CommonSolve]]
git-tree-sha1 = "332a332c97c7071600984b3c31d9067e1a4e6e25"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.1"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "5856d3031cdb1f3b2b6340dfdc66b6d9a149a374"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.2.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "fb21ddd70a051d882a1686a5a550990bbe371a95"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.4.1"

[[deps.Contour]]
git-tree-sha1 = "d05d9e7b7aedff4e5b51a029dced05cfb6125781"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.2"

[[deps.CpuId]]
deps = ["Markdown"]
git-tree-sha1 = "fcbb72b032692610bfbdb15018ac16a36cf2e406"
uuid = "adafc99b-e345-5852-983c-f28acb93d879"
version = "0.3.1"

[[deps.DataAPI]]
git-tree-sha1 = "1106fa7e1256b402a86a8e7b15c00c85036fef49"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.11.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelayDiffEq]]
deps = ["ArrayInterface", "DataStructures", "DiffEqBase", "LinearAlgebra", "Logging", "NonlinearSolve", "OrdinaryDiffEq", "Printf", "RecursiveArrayTools", "Reexport", "SciMLBase", "UnPack"]
git-tree-sha1 = "5acc7807b906d6a938dfeb965a6ea931260f054e"
uuid = "bcd4f6db-9728-5f36-b5f7-82caef46ccdb"
version = "5.38.0"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.DiffEqBase]]
deps = ["ArrayInterfaceCore", "ChainRulesCore", "DataStructures", "Distributions", "DocStringExtensions", "FastBroadcast", "ForwardDiff", "FunctionWrappers", "FunctionWrappersWrappers", "LinearAlgebra", "Logging", "MuladdMacro", "NonlinearSolve", "Parameters", "Printf", "RecursiveArrayTools", "Reexport", "Requires", "SciMLBase", "Setfield", "SparseArrays", "Static", "StaticArrays", "Statistics", "Tricks", "ZygoteRules"]
git-tree-sha1 = "0f9f82671406d21f6275cb6e9336259f062e81fa"
uuid = "2b5f629d-d688-5b77-993f-72d75c75574e"
version = "6.105.0"

[[deps.DiffEqCallbacks]]
deps = ["DataStructures", "DiffEqBase", "ForwardDiff", "LinearAlgebra", "Markdown", "NLsolve", "Parameters", "RecipesBase", "RecursiveArrayTools", "SciMLBase", "StaticArrays"]
git-tree-sha1 = "f8cc1ad62a87988225a07524ef84c7df7264c232"
uuid = "459566f4-90b8-5000-8ac3-15dfb0a30def"
version = "2.24.1"

[[deps.DiffEqNoiseProcess]]
deps = ["DiffEqBase", "Distributions", "GPUArraysCore", "LinearAlgebra", "Markdown", "Optim", "PoissonRandom", "QuadGK", "Random", "Random123", "RandomNumbers", "RecipesBase", "RecursiveArrayTools", "ResettableStacks", "SciMLBase", "StaticArrays", "Statistics"]
git-tree-sha1 = "8ba7a8913dc57c087d3cdc9b67eb1c9d760125bc"
uuid = "77a26b50-5914-5dd7-bc55-306e6241c503"
version = "5.13.0"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "992a23afdb109d0d2f8802a30cf5ae4b1fe7ea68"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.11.1"

[[deps.DifferentialEquations]]
deps = ["BoundaryValueDiffEq", "DelayDiffEq", "DiffEqBase", "DiffEqCallbacks", "DiffEqNoiseProcess", "JumpProcesses", "LinearAlgebra", "LinearSolve", "OrdinaryDiffEq", "Random", "RecursiveArrayTools", "Reexport", "SciMLBase", "SteadyStateDiffEq", "StochasticDiffEq", "Sundials"]
git-tree-sha1 = "f6b75cc940e8791b5cef04d29eb88731955e759c"
uuid = "0c46a032-eb83-5123-abaf-570d42b7fbaa"
version = "7.5.0"

[[deps.Distances]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "3258d0659f812acde79e8a74b11f17ac06d0ca04"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.7"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "0d7d213133d948c56e8c2d9f4eab0293491d8e4a"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.75"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "5158c2b41018c5f7eb1470d558127ac274eca0c9"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.1"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bad72f730e9e91c08d9427d5e8db95478a3c323d"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.4.8+0"

[[deps.ExponentialUtilities]]
deps = ["ArrayInterfaceCore", "GPUArraysCore", "GenericSchur", "LinearAlgebra", "Printf", "SparseArrays", "libblastrampoline_jll"]
git-tree-sha1 = "b19c3f5001b11b71d0f970f354677d604f3a1a97"
uuid = "d4d017d3-3776-5f7e-afef-a10c40355c18"
version = "1.19.0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Pkg", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "74faea50c1d007c85837327f6775bea60b5492dd"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.2+2"

[[deps.FastBroadcast]]
deps = ["ArrayInterface", "ArrayInterfaceCore", "LinearAlgebra", "Polyester", "Static", "StrideArraysCore"]
git-tree-sha1 = "21cdeff41e5a1822c2acd7fc7934c5f450588e00"
uuid = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
version = "0.2.1"

[[deps.FastClosures]]
git-tree-sha1 = "acebe244d53ee1b461970f8910c235b259e772ef"
uuid = "9aa1b823-49e4-5ca5-8b0f-3971ec8bab6a"
version = "0.3.2"

[[deps.FastLapackInterface]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "14a6f7a21125f715d935fe8f83560ee833f7d79d"
uuid = "29a986be-02c6-4525-aec4-84b980013641"
version = "1.2.7"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "87519eb762f85534445f5cda35be12e32759ee14"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.13.4"

[[deps.FiniteDiff]]
deps = ["ArrayInterfaceCore", "LinearAlgebra", "Requires", "Setfield", "SparseArrays", "StaticArrays"]
git-tree-sha1 = "5a2cff9b6b77b33b89f3d97a4d367747adce647e"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.15.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "187198a4ed8ccd7b5d99c41b69c679269ea2b2d4"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.32"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.FunctionWrappers]]
git-tree-sha1 = "241552bc2209f0fa068b6415b1942cc0aa486bcc"
uuid = "069b7b12-0de2-55c6-9aab-29f3d0a68a2e"
version = "1.1.2"

[[deps.FunctionWrappersWrappers]]
deps = ["FunctionWrappers"]
git-tree-sha1 = "a5e6e7f12607e90d71b09e6ce2c965e41b337968"
uuid = "77dc65aa-8811-40c2-897b-53d922fa7daf"
version = "0.1.1"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "d972031d28c8c8d9d7b41a536ad7bb0c2579caca"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.8+0"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "6872f5ec8fd1a38880f027a26739d42dcda6691f"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.2"

[[deps.GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "RelocatableFolders", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "0ac6f27e784059c68b987f42b909ade0bcfabe69"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.68.0"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "bc9f7725571ddb4ab2c4bc74fa397c1c5ad08943"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.69.1+0"

[[deps.GenericSchur]]
deps = ["LinearAlgebra", "Printf"]
git-tree-sha1 = "fb69b2a645fa69ba5f474af09221b9308b160ce6"
uuid = "c145ed77-6b09-5dd9-b285-bf645a82121e"
version = "0.5.3"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "fb83fbe02fe57f2c068013aa94bcdf6760d3a7a7"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.74.0+1"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "ba2d094a88b6b287bd25cfa86f301e7693ffae2f"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.7.4"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "Dates", "IniFile", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "4abede886fcba15cd5fd041fef776b230d004cee"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.4.0"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.HostCPUFeatures]]
deps = ["BitTwiddlingConvenienceFunctions", "IfElse", "Libdl", "Static"]
git-tree-sha1 = "b7b88a4716ac33fe31d6556c02fc60017594343c"
uuid = "3e5b6fbb-0976-4d2c-9146-d79de83f2fb0"
version = "0.1.8"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions", "Test"]
git-tree-sha1 = "709d864e3ed6e3545230601f94e11ebc65994641"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.11"

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[deps.Inflate]]
git-tree-sha1 = "5cd07aab533df5170988219191dfad0519391428"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.3"

[[deps.IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "49510dfcb407e572524ba94aeae2fced1f3feb0f"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.8"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IterativeSolvers]]
deps = ["LinearAlgebra", "Printf", "Random", "RecipesBase", "SparseArrays"]
git-tree-sha1 = "1169632f425f79429f245113b775a0e3d121457c"
uuid = "42fd0dbc-a981-5370-80f2-aaf504508153"
version = "0.9.2"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLFzf]]
deps = ["Pipe", "REPL", "Random", "fzf_jll"]
git-tree-sha1 = "f377670cda23b6b7c1c0b3893e37451c5c1a2185"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.5"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b53380851c6e6664204efb2e62cd24fa5c47e4ba"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.2+0"

[[deps.JumpProcesses]]
deps = ["ArrayInterfaceCore", "DataStructures", "DiffEqBase", "DocStringExtensions", "FunctionWrappers", "Graphs", "LinearAlgebra", "Markdown", "PoissonRandom", "Random", "RandomNumbers", "RecursiveArrayTools", "Reexport", "SciMLBase", "StaticArrays", "TreeViews", "UnPack"]
git-tree-sha1 = "5a6e6c522e8a7b39b24be8eebcc13cc7885c6f2c"
uuid = "ccbc3e58-028d-4f4c-8cd5-9ae44345cda5"
version = "9.2.0"

[[deps.KLU]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse_jll"]
git-tree-sha1 = "cae5e3dfd89b209e01bcd65b3a25e74462c67ee0"
uuid = "ef3ab10e-7fda-4108-b977-705223b18434"
version = "0.3.0"

[[deps.Krylov]]
deps = ["LinearAlgebra", "Printf", "SparseArrays"]
git-tree-sha1 = "92256444f81fb094ff5aa742ed10835a621aef75"
uuid = "ba0b0d4f-ebba-5204-a429-3ac8c609bfb7"
version = "0.8.4"

[[deps.KrylovKit]]
deps = ["LinearAlgebra", "Printf"]
git-tree-sha1 = "49b0c1dd5c292870577b8f58c51072bd558febb9"
uuid = "0b1a1467-8014-51b9-945f-bf0ae24f4b77"
version = "0.5.4"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Printf", "Requires"]
git-tree-sha1 = "ab9aa169d2160129beb241cb2750ca499b4e90e9"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.17"

[[deps.LayoutPointers]]
deps = ["ArrayInterface", "ArrayInterfaceOffsetArrays", "ArrayInterfaceStaticArrays", "LinearAlgebra", "ManualMemory", "SIMDTypes", "Static"]
git-tree-sha1 = "b67e749fb35530979839e7b4b606a97105fe4f1c"
uuid = "10f19ff3-798f-405d-979b-55457f8fc047"
version = "0.1.10"

[[deps.LevyArea]]
deps = ["LinearAlgebra", "Random", "SpecialFunctions"]
git-tree-sha1 = "56513a09b8e0ae6485f34401ea9e2f31357958ec"
uuid = "2d8b4e74-eb68-11e8-0fb9-d5eb67b50637"
version = "1.0.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "7739f837d6447403596a75d19ed01fd08d6f56bf"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.3.0+3"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LineSearches]]
deps = ["LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "Printf"]
git-tree-sha1 = "7bbea35cec17305fc70a0e5b4641477dc0789d9d"
uuid = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
version = "7.2.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LinearSolve]]
deps = ["ArrayInterfaceCore", "DocStringExtensions", "FastLapackInterface", "GPUArraysCore", "IterativeSolvers", "KLU", "Krylov", "KrylovKit", "LinearAlgebra", "RecursiveFactorization", "Reexport", "SciMLBase", "Setfield", "SparseArrays", "SuiteSparse", "UnPack"]
git-tree-sha1 = "c17007396b2ae56b8496f5a9857326dea0b7bb7b"
uuid = "7ed4a6bd-45f5-4d41-b270-4a48e9bafcae"
version = "1.26.0"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "94d9c52ca447e23eac0c0f074effbcd38830deb5"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.18"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "5d4d2d9904227b8bd66386c1138cf4d5ffa826bf"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "0.4.9"

[[deps.LoopVectorization]]
deps = ["ArrayInterface", "ArrayInterfaceCore", "ArrayInterfaceOffsetArrays", "ArrayInterfaceStaticArrays", "CPUSummary", "ChainRulesCore", "CloseOpenIntervals", "DocStringExtensions", "ForwardDiff", "HostCPUFeatures", "IfElse", "LayoutPointers", "LinearAlgebra", "OffsetArrays", "PolyesterWeave", "SIMDDualNumbers", "SIMDTypes", "SLEEFPirates", "SnoopPrecompile", "SpecialFunctions", "Static", "ThreadingUtilities", "UnPack", "VectorizationBase"]
git-tree-sha1 = "f06e8b4861f5f84b7041881e0c35f633b2a86bef"
uuid = "bdcacae8-1622-11e9-2a5c-532679323890"
version = "0.12.130"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.ManualMemory]]
git-tree-sha1 = "bcaef4fc7a0cfe2cba636d84cda54b5e4e4ca3cd"
uuid = "d125e4d3-2237-4719-b19c-fa641b8a4667"
version = "0.1.8"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "Random", "Sockets"]
git-tree-sha1 = "6872f9594ff273da6d13c7c1a1545d5a8c7d0c1c"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.6"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.MuladdMacro]]
git-tree-sha1 = "c6190f9a7fc5d9d5915ab29f2134421b12d24a68"
uuid = "46d2c3a1-f734-5fdb-9937-b9b9aeba4221"
version = "0.2.2"

[[deps.NLSolversBase]]
deps = ["DiffResults", "Distributed", "FiniteDiff", "ForwardDiff"]
git-tree-sha1 = "50310f934e55e5ca3912fb941dec199b49ca9b68"
uuid = "d41bc354-129a-5804-8e4c-c37616107c6c"
version = "7.8.2"

[[deps.NLsolve]]
deps = ["Distances", "LineSearches", "LinearAlgebra", "NLSolversBase", "Printf", "Reexport"]
git-tree-sha1 = "019f12e9a1a7880459d0173c182e6a99365d7ac1"
uuid = "2774e3e8-f4cf-5e23-947b-6d7e65073b56"
version = "4.5.1"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "a7c3d1da1189a1c2fe843a3bfa04d18d20eb3211"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.NonlinearSolve]]
deps = ["ArrayInterfaceCore", "FiniteDiff", "ForwardDiff", "IterativeSolvers", "LinearAlgebra", "RecursiveArrayTools", "RecursiveFactorization", "Reexport", "SciMLBase", "Setfield", "StaticArrays", "UnPack"]
git-tree-sha1 = "a754a21521c0ab48d37f44bbac1eefd1387bdcfc"
uuid = "8913a72c-1f9b-4ce2-8d82-65094dcecaec"
version = "0.3.22"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "1ea784113a6aa054c5ebd95945fa5e52c2f378e7"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.7"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "02be9f845cb58c2d6029a6d5f67f4e0af3237814"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.1.3"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e60321e3f2616584ff98f0a4f18d98ae6f89bbb3"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.17+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Optim]]
deps = ["Compat", "FillArrays", "ForwardDiff", "LineSearches", "LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "PositiveFactorizations", "Printf", "SparseArrays", "StatsBase"]
git-tree-sha1 = "b9fe76d1a39807fdcf790b991981a922de0c3050"
uuid = "429524aa-4258-5aef-a3af-852621145aeb"
version = "1.7.3"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.OrdinaryDiffEq]]
deps = ["Adapt", "ArrayInterface", "ArrayInterfaceGPUArrays", "ArrayInterfaceStaticArrays", "DataStructures", "DiffEqBase", "DocStringExtensions", "ExponentialUtilities", "FastBroadcast", "FastClosures", "FiniteDiff", "ForwardDiff", "FunctionWrappersWrappers", "LinearAlgebra", "LinearSolve", "Logging", "LoopVectorization", "MacroTools", "MuladdMacro", "NLsolve", "NonlinearSolve", "Polyester", "PreallocationTools", "Preferences", "RecursiveArrayTools", "Reexport", "SciMLBase", "SnoopPrecompile", "SparseArrays", "SparseDiffTools", "StaticArrays", "UnPack"]
git-tree-sha1 = "06dbf3ab4f2530d5c5464f78c9aba4cc300ed069"
uuid = "1dea7af3-3e70-54e6-95c3-0bf5283fa5ed"
version = "6.28.0"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "cf494dca75a69712a72b80bc48f59dcf3dea63ec"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.16"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "3d5bf43e3e8b412656404ed9466f1dcbf7c50269"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.4.0"

[[deps.Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "8162b2f8547bc23876edd0c5181b27702ae58dce"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.0.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "SnoopPrecompile", "Statistics"]
git-tree-sha1 = "21303256d239f6b484977314674aef4bb1fe4420"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.3.1"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SnoopPrecompile", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "Unzip"]
git-tree-sha1 = "284a353a34a352a95fca1d61ea28a0d48feaf273"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.34.4"

[[deps.PoissonRandom]]
deps = ["Random"]
git-tree-sha1 = "9ac1bb7c15c39620685a3a7babc0651f5c64c35b"
uuid = "e409e4f3-bfea-5376-8464-e040bb5c01ab"
version = "0.4.1"

[[deps.Polyester]]
deps = ["ArrayInterface", "BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "ManualMemory", "PolyesterWeave", "Requires", "Static", "StrideArraysCore", "ThreadingUtilities"]
git-tree-sha1 = "6ee5518f7baa05e154757a003bfb6936a174dbad"
uuid = "f517fe37-dbe3-4b94-8317-1923a5111588"
version = "0.6.15"

[[deps.PolyesterWeave]]
deps = ["BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "Static", "ThreadingUtilities"]
git-tree-sha1 = "b42fb2292fbbaed36f25d33a15c8cc0b4f287fcf"
uuid = "1d0040c9-8b98-4ee7-8388-3f51789ca0ad"
version = "0.1.10"

[[deps.PositiveFactorizations]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "17275485f373e6673f7e7f97051f703ed5b15b20"
uuid = "85a6dd25-e78a-55b7-8502-1745935b8125"
version = "0.2.4"

[[deps.PreallocationTools]]
deps = ["Adapt", "ArrayInterfaceCore", "ForwardDiff"]
git-tree-sha1 = "3953d18698157e1d27a51678c89c88d53e071a42"
uuid = "d236fae5-4411-538c-8e31-a6e3d9e00b46"
version = "0.4.4"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "c6c0f690d0cc7caddb74cef7aa847b824a16b256"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+1"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "3c009334f45dfd546a16a57960a821a1a023d241"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.5.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Random123]]
deps = ["Random", "RandomNumbers"]
git-tree-sha1 = "7a1a306b72cfa60634f03a911405f4e64d1b718b"
uuid = "74087812-796a-5b5d-8853-05524746bad3"
version = "1.6.0"

[[deps.RandomNumbers]]
deps = ["Random", "Requires"]
git-tree-sha1 = "043da614cc7e95c703498a491e2c21f58a2b8111"
uuid = "e6cf234a-135c-5ec9-84dd-332b85af5143"
version = "1.5.3"

[[deps.RecipesBase]]
deps = ["SnoopPrecompile"]
git-tree-sha1 = "612a4d76ad98e9722c8ba387614539155a59e30c"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.0"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "e7eac76a958f8664f2718508435d058168c7953d"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.3"

[[deps.RecursiveArrayTools]]
deps = ["Adapt", "ArrayInterfaceCore", "ArrayInterfaceStaticArraysCore", "ChainRulesCore", "DocStringExtensions", "FillArrays", "GPUArraysCore", "IteratorInterfaceExtensions", "LinearAlgebra", "RecipesBase", "StaticArraysCore", "Statistics", "Tables", "ZygoteRules"]
git-tree-sha1 = "3004608dc42101a944e44c1c68b599fa7c669080"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "2.32.0"

[[deps.RecursiveFactorization]]
deps = ["LinearAlgebra", "LoopVectorization", "Polyester", "SnoopPrecompile", "StrideArraysCore", "TriangularSolve"]
git-tree-sha1 = "0a2dfb3358fcde3676beb75405e782faa8c9aded"
uuid = "f2c3362d-daeb-58d1-803e-2bc74f2840b4"
version = "0.2.12"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "90bc7a7c96410424509e4263e277e43250c05691"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.0"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.ResettableStacks]]
deps = ["StaticArrays"]
git-tree-sha1 = "256eeeec186fa7f26f2801732774ccf277f05db9"
uuid = "ae5879a3-cd67-5da8-be7f-38c6eb64a37b"
version = "1.1.1"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.SIMDDualNumbers]]
deps = ["ForwardDiff", "IfElse", "SLEEFPirates", "VectorizationBase"]
git-tree-sha1 = "dd4195d308df24f33fb10dde7c22103ba88887fa"
uuid = "3cdde19b-5bb0-4aaf-8931-af3e248e098b"
version = "0.1.1"

[[deps.SIMDTypes]]
git-tree-sha1 = "330289636fb8107c5f32088d2741e9fd7a061a5c"
uuid = "94e857df-77ce-4151-89e5-788b33177be4"
version = "0.1.0"

[[deps.SLEEFPirates]]
deps = ["IfElse", "Static", "VectorizationBase"]
git-tree-sha1 = "2ba4fee025f25d6711487b73e1ac177cbd127913"
uuid = "476501e8-09a2-5ece-8869-fb82de89a1fa"
version = "0.6.35"

[[deps.SciMLBase]]
deps = ["ArrayInterfaceCore", "CommonSolve", "ConstructionBase", "Distributed", "DocStringExtensions", "FunctionWrappersWrappers", "IteratorInterfaceExtensions", "LinearAlgebra", "Logging", "Markdown", "Preferences", "RecipesBase", "RecursiveArrayTools", "StaticArraysCore", "Statistics", "Tables"]
git-tree-sha1 = "2c7b9be95f91c971ae4e4a6e3a0556b839874f2b"
uuid = "0bca4576-84f4-4d90-8ffe-ffa030f20462"
version = "1.59.4"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "f94f779c94e58bf9ea243e77a37e16d9de9126bd"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "Requires"]
git-tree-sha1 = "38d88503f695eb0301479bc9b0d4320b378bafe5"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "0.8.2"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.SnoopPrecompile]]
git-tree-sha1 = "f604441450a3c0569830946e5b33b78c928e1a85"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.1"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SparseDiffTools]]
deps = ["Adapt", "ArrayInterfaceCore", "ArrayInterfaceStaticArrays", "Compat", "DataStructures", "FiniteDiff", "ForwardDiff", "Graphs", "LinearAlgebra", "Requires", "SparseArrays", "StaticArrays", "VertexSafeGraphs"]
git-tree-sha1 = "5fb8ba9180f467885e87a2c99cae178b67934be1"
uuid = "47a9eef4-7e08-11e9-0b38-333d64bd3804"
version = "1.26.2"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "d75bda01f8c31ebb72df80a46c88b25d1c79c56d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.7"

[[deps.Static]]
deps = ["IfElse"]
git-tree-sha1 = "de4f0a4f049a4c87e4948c04acff37baf1be01a6"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.7.7"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "f86b3a049e5d05227b10e15dbb315c5b90f14988"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.9"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6b7ba252635a5eff6a0b0664a41ee140a1c9e72a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f9af7f195fb13589dd2e2d57fdb401717d2eb1f6"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.5.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "HypergeometricFunctions", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "5783b877201a82fc0014cbf381e7e6eb130473a4"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.0.1"

[[deps.SteadyStateDiffEq]]
deps = ["DiffEqBase", "DiffEqCallbacks", "LinearAlgebra", "NLsolve", "Reexport", "SciMLBase"]
git-tree-sha1 = "f4492f790434f405139eb3a291fdbb45997857c6"
uuid = "9672c7b4-1e72-59bd-8a11-6ac3964bc41f"
version = "1.9.0"

[[deps.StochasticDiffEq]]
deps = ["Adapt", "ArrayInterface", "DataStructures", "DiffEqBase", "DiffEqNoiseProcess", "DocStringExtensions", "FillArrays", "FiniteDiff", "ForwardDiff", "JumpProcesses", "LevyArea", "LinearAlgebra", "Logging", "MuladdMacro", "NLsolve", "OrdinaryDiffEq", "Random", "RandomNumbers", "RecursiveArrayTools", "Reexport", "SciMLBase", "SparseArrays", "SparseDiffTools", "StaticArrays", "UnPack"]
git-tree-sha1 = "8062351f645bb23725c494be74619ef802a2ffa8"
uuid = "789caeaf-c7a9-5a7d-9973-96adeb23e2a0"
version = "6.54.0"

[[deps.StrideArraysCore]]
deps = ["ArrayInterface", "CloseOpenIntervals", "IfElse", "LayoutPointers", "ManualMemory", "SIMDTypes", "Static", "ThreadingUtilities"]
git-tree-sha1 = "ac730bd978bf35f9fe45daa0bd1f51e493e97eb4"
uuid = "7792a7ef-975c-4747-a70f-980b88e8d1da"
version = "0.3.15"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"

[[deps.Sundials]]
deps = ["CEnum", "DataStructures", "DiffEqBase", "Libdl", "LinearAlgebra", "Logging", "Reexport", "SnoopPrecompile", "SparseArrays", "Sundials_jll"]
git-tree-sha1 = "5717b2c13ddc167d7db931bfdd1a94133ee1d4f0"
uuid = "c3572dad-4567-51f8-b174-8c6c989267f4"
version = "4.10.1"

[[deps.Sundials_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "OpenBLAS_jll", "Pkg", "SuiteSparse_jll"]
git-tree-sha1 = "04777432d74ec5bc91ca047c9e0e0fd7f81acdb6"
uuid = "fb77eaff-e24c-56d4-86b1-d163f2edb164"
version = "5.2.1+0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "2d7164f7b8a066bcfa6224e67736ce0eb54aef5b"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.9.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.ThreadingUtilities]]
deps = ["ManualMemory"]
git-tree-sha1 = "f8629df51cab659d70d2e5618a430b4d3f37f2c3"
uuid = "8290d209-cae3-49c0-8002-c8c24d57dab5"
version = "0.5.0"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "8a75929dcd3c38611db2f8d08546decb514fcadf"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.9"

[[deps.TreeViews]]
deps = ["Test"]
git-tree-sha1 = "8d0d7a3fe2f30d6a7f833a5f19f7c7a5b396eae6"
uuid = "a2a6695c-b41b-5b7d-aed9-dbfdeacea5d7"
version = "0.3.0"

[[deps.TriangularSolve]]
deps = ["CloseOpenIntervals", "IfElse", "LayoutPointers", "LinearAlgebra", "LoopVectorization", "Polyester", "SnoopPrecompile", "Static", "VectorizationBase"]
git-tree-sha1 = "fdddcf6b2c7751cd97de69c18157aacc18fbc660"
uuid = "d5829a12-d9aa-46ab-831f-fb7c9ab06edf"
version = "0.1.14"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.URIs]]
git-tree-sha1 = "e59ecc5a41b000fa94423a578d29290c7266fc10"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.VectorizationBase]]
deps = ["ArrayInterface", "CPUSummary", "HostCPUFeatures", "IfElse", "LayoutPointers", "Libdl", "LinearAlgebra", "SIMDTypes", "Static"]
git-tree-sha1 = "4699578969f75c56ca6a7814c54511cdf04a4966"
uuid = "3d5dd08c-fd9d-11e8-17fa-ed2836048c2f"
version = "0.21.50"

[[deps.VertexSafeGraphs]]
deps = ["Graphs"]
git-tree-sha1 = "8351f8d73d7e880bfc042a8b6922684ebeafb35c"
uuid = "19fa3120-7c27-5ec5-8db8-b0b0aa330d6f"
version = "0.2.0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "3e61f0b86f90dacb0bc0e73a0c5a83f6a8636e23"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.19.0+0"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4528479aa01ee1b3b4cd0e6faef0e04cf16466da"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.25.0+0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "58443b63fb7e465a8a7210828c91c08b92132dff"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.14+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e45044cd873ded54b6a5bac0eb5c971392cf1927"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.2+0"

[[deps.ZygoteRules]]
deps = ["MacroTools"]
git-tree-sha1 = "8c1a8e4dfacb1fd631745552c8db35d0deb09ea0"
uuid = "700de1a5-db45-46bc-99cf-38207098b444"
version = "0.2.2"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "868e669ccb12ba16eaf50cb2957ee2ff61261c56"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.29.0+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a2ea60308f0996d26f1e5354e10c24e9ef905d4"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.4.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "9ebfc140cc56e8c2156a15ceac2f0302e327ac0a"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+0"
"""

# ╔═╡ Cell order:
# ╠═5699b85e-0f55-11ed-0865-9fbd5aa9097c
# ╟─5ba9125c-262e-4a31-9515-109463527031
# ╟─d7d2e805-781f-4b07-9adc-9c75acc66bc9
# ╟─68a95dca-e8ce-4253-a068-1cd2cfac893a
# ╟─9ec881e2-3a6f-47c6-a900-40376f929f3f
# ╠═dbe0b543-3c51-4732-88ec-364064088380
# ╟─373f650b-86d1-45ca-aad8-613940e2f788
# ╠═a1ce46ff-f4e1-4a84-b1d0-31c67cc7523a
# ╠═73d3bf5e-8626-4a7f-9404-a953c59d5989
# ╠═ff6ebf08-69b3-4d3c-82b4-af70f12ddd30
# ╠═cd6203d6-dd50-4d03-9ac1-0400e124b1e0
# ╟─ea76cc50-1005-4902-87f2-85ba43525134
# ╠═caba579c-5cce-42c0-8293-19b3bbe8a1fa
# ╠═8a05aeea-be56-4b46-a42c-6356c2de73ed
# ╟─239075d6-fde1-4794-825c-1bd4e9380681
# ╠═c21a9f39-518c-4fbc-af2f-db27e33a2d1d
# ╠═cb7222c4-4530-4c25-9123-894a0ae7a184
# ╠═10cfbe02-510c-4d52-9133-d51adb26deb2
# ╟─0515150e-6e13-4cc4-b68f-61708a3cf4f4
# ╠═d74f8588-a7da-4001-8bea-e981bfdbd61b
# ╠═9da98062-6c3b-49e3-8b96-92dcc89769c7
# ╠═47b8fa14-6162-49c6-9d21-4b4d0ae09de2
# ╠═316fd5e6-f050-46db-8239-a39ee7a2a593
# ╟─a8f21b8d-f99e-4b51-91cd-981a99ac1a27
# ╠═d1ede4d9-0d7b-43c2-aeb7-cf45a7f1d044
# ╠═a1524118-a9ac-46c4-a2cb-f54ca214c59c
# ╟─a5fa4f83-3169-4268-b816-7b8fe2c5333a
# ╠═35f58720-56f4-4cce-adab-95414062f3d0
# ╟─223a382a-3ebb-43f6-9773-c48ebd3e0569
# ╠═e606d381-d37e-414d-9c68-c65205e61873
# ╠═bf1f9690-6dda-4a1f-8d6d-377360878fab
# ╟─33c3a10f-0527-4a04-9851-9b43560f501c
# ╠═8abdec27-c63a-4b4f-ade9-0cfa674b22dd
# ╟─df275c47-7936-442e-9771-5c9c4cb6e46f
# ╠═ecd0f578-2614-4473-af25-0db650688a06
# ╟─605d0f30-3039-4cd3-93d8-852b5e0ba141
# ╠═29da6749-52fb-4881-88d8-556613629dac
# ╟─b5832d59-7550-4899-83a5-3ee111cda9c0
# ╟─c0924df8-3a8f-4923-b341-e77e692fcb84
# ╠═84d5d1f3-3592-470b-a75d-c210cbfd8171
# ╠═382ec6b5-4560-4579-9886-040816d786f4
# ╠═3d5b13b8-fb58-463b-ad6c-782f110f7126
# ╠═2165ddff-931b-418c-9593-dea517d0b97f
# ╟─70eb4406-cb25-4d69-abbb-ab2555b5ec1f
# ╠═3a6d1ded-a7f3-403c-83e4-79800a5caf62
# ╠═35079b88-7f36-41e2-bfe0-8a261cb53cf6
# ╠═7618d869-956d-4f8d-898d-328809e05799
# ╠═549b7fd4-398a-4571-aec6-796aa9f6d009
# ╠═a578169c-242a-4f61-9f36-4b61b0b6f1a4
# ╠═f55155e9-5652-4ac2-8af8-be28407d89bc
# ╠═4365210a-3929-4407-a43f-2068cf1cf3a3
# ╠═02fe3358-f2c4-4b6e-b616-a3cbaed1ae96
# ╠═9e1c764f-b974-40f2-a20d-46974932a9b9
# ╠═33c69cfe-f780-4b4a-8c18-4d66cfbf8c3e
# ╠═c4ad6249-a53d-4163-b440-3beb34547268
# ╠═32b5c382-b93c-45cd-af18-5edbd7179f61
# ╠═d1c325ed-b1b9-4cad-b9d4-da41c77fdf6b
# ╟─8d702baa-8fb4-4ef4-ad31-b10404243a2e
# ╠═7cde7ad7-a15b-4cde-a284-e8cea08b3a68
# ╠═60771243-3d3d-454e-94b9-08c7f25bfe87
# ╠═5329928c-fa5c-4352-ae30-75166f4ba9b6
# ╠═6b9793c6-d42e-4be6-b99f-d7792c83b493
# ╠═ca8880e3-70df-432c-a30d-9bb85163bc9d
# ╠═99c0d98a-65e2-43d4-9a50-1f7399f121ec
# ╠═bf740022-9c97-456b-8072-7500d52bf704
# ╠═c9719d0a-ba5a-4873-ab3c-ce263e0c8438
# ╠═18de5b83-20e6-46e6-bd83-8f7945937198
# ╠═9b9ec907-d4b6-44f0-b638-bafb75352d20
# ╠═93c553ee-9938-4119-aa91-803823af0def
# ╠═fac222c7-ca4a-44ae-a966-d68fac57f0c5
# ╠═3218a55b-5ebe-4ffa-a4b8-3e93c89c3e0d
# ╠═9cdd578d-d448-4eac-a976-39a1b7340993
# ╠═58da3aed-b3f6-441c-ac4b-274d36a247d5
# ╠═903f4520-35ca-41d4-8ebc-bca57d59d329
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
