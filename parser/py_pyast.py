from ast import parse, AST, expr, unaryop, operator, Constant, cmpop, boolop
import ast
from enum import Enum

try:
  from lxml import etree as ET
except ImportError:
    import xml.etree.ElementTree as ET
from sys import argv

pyast_ns = "http:/ki.ujep.cz/ns/py_ast"
qc_ns = "http:/ki.ujep.cz/ns/qc_ast"

def with_ns(tag, ns):
    return f"{{{ns}}}{tag}"


class OperatorType(Enum):
    Arithmetic = 0
    Boolean = 1
    Bitwise = 2
    Relational = 3


unaryop_map = {ast.UAdd: ("+", OperatorType.Arithmetic),
               ast.USub: ("-", OperatorType.Arithmetic),
               ast.Not: ("not", OperatorType.Boolean),
               ast.Invert: ("~", OperatorType.Bitwise)
               }
binop_map = {ast.Add: ("+", OperatorType.Arithmetic),
             ast.Sub: ("-", OperatorType.Arithmetic),
             ast.Mult: ("*", OperatorType.Arithmetic),
             ast.MatMult: ("@", OperatorType.Arithmetic),
             ast.Div: ("/", OperatorType.Arithmetic),
             ast.FloorDiv: ("//", OperatorType.Arithmetic),
             ast.Mod: ("%", OperatorType.Arithmetic),
             ast.Pow: ("**", OperatorType.Arithmetic),
             ast.LShift: ("<<", OperatorType.Bitwise),
             ast.RShift: (">>", OperatorType.Bitwise),
             ast.BitOr: ("|", OperatorType.Bitwise),
             ast.BitAnd: ("&", OperatorType.Bitwise),
             ast.BitXor: ("^", OperatorType.Bitwise)
             }
comparator_map = {ast.Gt: ">", ast.GtE: ">=", ast.Lt: "<", ast.LtE: "<=", ast.Eq: "==",
                  ast.NotEq: "!=", ast.In: "in", ast.NotIn: "not in", ast.Is: "is",
                  ast.IsNot: "is not"}
boolop_map = {ast.And: "and", ast.Or: "or"}


def const_type(node, fieldnode):
    fieldnode.set("type", node.value.__class__.__name__)


def generate(ast_node: AST, xtree, in_expression=False):
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
                                  symbol=comparator_map[item.__class__],
                                  type=str(OperatorType.Relational.name).lower())
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
                              symbol=unaryop_map[attrval.__class__][0],
                              type=str(unaryop_map[attrval.__class__][1].name).lower()
                              )
            case operator():
                ET.SubElement(node, with_ns("operator", pyast_ns),
                              symbol=binop_map[attrval.__class__][0],
                              type=str(binop_map[attrval.__class__][1].name).lower()
                )
            case boolop():
                ET.SubElement(node, with_ns("operator", pyast_ns),
                              symbol=boolop_map[attrval.__class__],
                              type=OperatorType.Boolean.name.lower())
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


def process_string(s: str, simplify_xslt, qcast_xslt):
    from lxml import etree
    ast = parse(s)
    ET.register_namespace("py", pyast_ns)
    ET.register_namespace("qc", qc_ns)
    root = ET.Element(f"{{{pyast_ns}}}ast")
    generate(ast, root)
    simplify = etree.XSLT(ET.parse(simplify_xslt))
    sroot = simplify(root)
    qcast = etree.XSLT(ET.parse(qcast_xslt))
    qroot = qcast(sroot)
    return qroot


if __name__ == "__main__":
    ast = parse(open(argv[1], "rt").read())
    ET.register_namespace("py", pyast_ns)
    ET.register_namespace("qc", qc_ns)
    root = ET.Element(f"{{{pyast_ns}}}ast")
    generate(ast, root)
    print(ET.tostring(root, encoding="unicode"))