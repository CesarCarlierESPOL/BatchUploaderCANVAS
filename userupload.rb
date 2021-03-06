require 'csv'
require 'net/http'
require 'httparty'
require 'uri'
require 'json'

def getUsers
    url = 'http://localhost:3000/api/v1/accounts/1/users'
    response = HTTParty.get(url, headers:{"Authorization" => "Bearer zQKd8yK7Okvcv6IPAPuepXTuThaT52cCrjmKC4XkaXvxs9EWaLoy7FdSMS8N3OPV"})
    puts response.parsed_response
end

#***********/ Codigo oficial /***********

#***********/ Metodos /***********
def cargarDatos(archivo)
    #Carga datos de los csv en arrays 2D con headers a los que se puede acceder
    datos = CSV.parse(File.read(archivo), headers: true)
    return datos
end

def postCurso(materia,codigo)
    url = 'http://localhost:3000/api/v1/accounts/1/courses'
    response = HTTParty.post(url, headers:{"Authorization" => "Bearer zQKd8yK7Okvcv6IPAPuepXTuThaT52cCrjmKC4XkaXvxs9EWaLoy7FdSMS8N3OPV"}, body:{"course":{"name":materia,"course_code":codigo},"offer":true})
    response.parsed_response
    puts response
end

def postUsuario(nombres,apellidos,correo,clave,cedula)
    url = 'http://localhost:3000/api/v1/accounts/1/users'
    response = HTTParty.post(url, headers:{"Authorization" => "Bearer zQKd8yK7Okvcv6IPAPuepXTuThaT52cCrjmKC4XkaXvxs9EWaLoy7FdSMS8N3OPV"}, body:{"user":{"name":nombres+" "+apellidos},"pseudonym":{"unique_id":correo, "password":clave, "sis_user_id":cedula}})
    puts response.parsed_response
    return
end

def buscarIdUsuario(codigo)
    url = 'http://localhost:3000/api/v1/accounts/1/users'
    response = HTTParty.get(url, headers:{"Authorization" => "Bearer zQKd8yK7Okvcv6IPAPuepXTuThaT52cCrjmKC4XkaXvxs9EWaLoy7FdSMS8N3OPV"}, body:{"search_term":codigo})
    return response.parsed_response[0]["id"]
    
end

def buscarIdMateria(codigo)
    url = 'http://localhost:3000/api/v1/accounts/1/courses'
    response = HTTParty.get(url, headers:{"Authorization" => "Bearer zQKd8yK7Okvcv6IPAPuepXTuThaT52cCrjmKC4XkaXvxs9EWaLoy7FdSMS8N3OPV"}, body:{"search_term":codigo})
    return response.parsed_response[0]["id"]
    
end

def postEnrollment(codigoMateria,codigoEstudiante,tipoEnrollment)
    url = 'http://localhost:3000/api/v1/courses/'+codigoMateria.to_s+'/enrollments'
    response = HTTParty.post(url,headers:{"Authorization" => "Bearer zQKd8yK7Okvcv6IPAPuepXTuThaT52cCrjmKC4XkaXvxs9EWaLoy7FdSMS8N3OPV"}, body:{"enrollment":{"user_id":codigoEstudiante, "type":tipoEnrollment,"enrollment_state":"active"}})
    puts response
end

#***********/ Main /***********
#Carga de datos
datosEstudiantes = cargarDatos("estudiantes.csv")
datosProfesores = cargarDatos("profesores.csv")
datosMaterias = cargarDatos("materias.csv")
materiasPorGrado = Hash.new
estudiantesPorGrado = Hash.new
MateriaPorProfesor = Hash.new

#Ingresar Materias
for materiaRow in datosMaterias do
    postCurso(materiaRow["materia"],materiaRow["codigo"])
    unless materiasPorGrado.has_key?(materiaRow["grado"])
        materiasPorGrado[materiaRow["grado"]] = []           
    end
    materiasPorGrado[materiaRow["grado"]].push(materiaRow["codigo"])

    unless MateriaPorProfesor.has_key?(materiaRow["profesor"])
        MateriaPorProfesor[materiaRow["profesor"]] = []           
    end
    MateriaPorProfesor[materiaRow["profesor"]].push(materiaRow["codigo"])

    
end

#Ingresar Alumnos
for estudianteRow in datosEstudiantes do
    postUsuario(estudianteRow["nombres"],estudianteRow["apellidos"],estudianteRow["correo"],estudianteRow["cedula"],estudianteRow["cedula"])
    unless estudiantesPorGrado.has_key?(estudianteRow["grado"])
        estudiantesPorGrado[estudianteRow["grado"]] = []           
    end
    estudiantesPorGrado[estudianteRow["grado"]].push(estudianteRow["cedula"])
end

#Ingresar Profesores y registrarlos en materias
for profesorRow in datosProfesores do
    postUsuario(profesorRow["nombres"],profesorRow["apellidos"],profesorRow["correo"],profesorRow["cedula"],profesorRow["cedula"])
    if MateriaPorProfesor.has_key?(profesorRow["cedula"])
        for codigoMateria in MateriaPorProfesor[profesorRow["cedula"]] do
            idProfesor = buscarIdUsuario(profesorRow["cedula"])
            idMateria = buscarIdMateria(codigoMateria)
            postEnrollment(idMateria,idProfesor,"TeacherEnrollment")
        end
    end
end 

#Registrar alumnos a sus materias respectivas
estudiantesPorGrado.each do |grado, lista|
    for codigoAlumno in lista do
        idEstudiante = buscarIdUsuario(codigoAlumno)
        for codigoMateria in materiasPorGrado[grado] do
            idMateria = buscarIdMateria(codigoMateria)
            postEnrollment(idMateria,idEstudiante,"StudentEnrollment")
        end
    end
end