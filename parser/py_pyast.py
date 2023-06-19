from ast import parse, AST, expr, unaryop, operator, Constant, cmpop, boolop
import ast
import xml.etree.ElementTree as ET
from sys import argv

pyast_ns = "http:/ki.ujep.cz/ns/py_ast"
qc_ns = "http:/ki.ujep.cz/ns/qc_ast"


def with_ns(tag, ns):
    return f"{{{ns}}}{tag}"


unaryop_map = {ast.UAdd: "+", ast.USub: "-", ast.Not: "not", ast.Invert: "~"}
binop_map = {ast.Add: "+", ast.Sub: "-", ast.Mult: "*", ast.MatMult: "@",
             ast.Div: "/", ast.FloorDiv: "//", ast.Mod: "%", ast.Pow: "**",
             ast.LShift: "<<", ast.RShift: ">>", ast.BitOr: "|", ast.BitAnd: "&", ast.BitXor: "^"}
comparator_map = {ast.Gt: ">", ast.GtE: ">=", ast.Lt: "<", ast.LtE: "<=", ast.Eq: "==",
                  ast.NotEq: "!=", ast.In: "in", ast.NotIn: "not in", ast.Is: "is",
                  ast.IsNot: "is not"}
boolop_map = {ast.And: "and", ast.Or: "or"}


def const_type(node, fieldnode):
    fieldnode.set("type", node.value.__class__.__name__)


def generate(ast_node: AST, xtree: ET.Element, in_expression=False):
    node = ET.SubElement(xtree, with_ns(ast_node.__class__.__name__, pyast_ns))
    if isinstance(ast_node, Constant):
        const_type(ast_node, node)
    for name in ast_node._fields:
        attrval = ast_node.__getattribute__(name)
        match attrval:
            case list():
                fieldnode = ET.SubElement(node, with_ns(name, pyast_ns))
                for item in attrval:
                    match item:
                        case cmpop():
                            ET.SubElement(fieldnode, with_ns("operator", pyast_ns),
                                  symbol=comparator_map[item.__class__])
                        case expr() if not in_expression:
                            exprnode = ET.SubElement(fieldnode, with_ns("expression", qc_ns))
                            generate(item, exprnode, True)
                        case AST():
                            generate(item, fieldnode, in_expression)
                        case str():
                            if fieldnode.text:
                                fieldnode.text += "," + item
                            else:
                                fieldnode.text = item
                        case None:
                            ET.SubElement(fieldnode, with_ns("empty", pyast_ns))
                        case _:
                            raise Exception(f"Invalid item of collection {item} type:{item.__class__.__name__}")
            case unaryop():
                ET.SubElement(node, with_ns("operator", pyast_ns),
                              symbol=unaryop_map[attrval.__class__])
            case operator():
                ET.SubElement(node, with_ns("operator", pyast_ns),
                              symbol=binop_map[attrval.__class__])
            case boolop():
                ET.SubElement(node, with_ns("operator", pyast_ns),
                              symbol=boolop_map[attrval.__class__])
            case expr() if not in_expression:
                fieldnode = ET.SubElement(node, with_ns(name, pyast_ns))
                exprnode = ET.SubElement(fieldnode, with_ns("expression", qc_ns))
                generate(attrval, exprnode, True)
            case AST():
                fieldnode = ET.SubElement(node, with_ns(name, pyast_ns))
                generate(attrval, fieldnode, in_expression)
            case None:
                pass
            case _:
                node.set(name, str(attrval))


ast = parse(open(argv[1], "rt").read())
ET.register_namespace("py", pyast_ns)
ET.register_namespace("", qc_ns)
root = ET.Element(f"{{{pyast_ns}}}ast")
generate(ast, root)
print(ET.tostring(root, encoding="unicode"))