import model
from sqlalchemy_schemadisplay import create_uml_graph
from sqlalchemy.orm import class_mapper

# lets find all the mappers in our model
mappers = []
for attr in dir(model):
    if attr[0] == "_":
        continue
    try:
        cls = getattr(model, attr)
        mappers.append(class_mapper(cls))
    except Exception:
        pass

# pass them to the function and set some formatting options
graph = create_uml_graph(mappers, show_operations=False, show_multiplicity_one=True)
graph.write_png("schema.png")
